// lib/services/api_usage.dart
// ══════════════════════════════════════════════════════════════════════════
//  API usage tracking + client-side rate limiting.
//
//  • Every request made through ApiHttp is counted per API (total, today,
//    errors, rate-limited, skipped by the limiter, last call).
//  • A sliding-window limiter keeps the app under each provider's limit
//    (see api_registry.dart). A request that would have to wait longer than
//    the API's maxWaitMs is skipped instead, so callers fall back to their
//    next source rather than hanging.
//  • After a rate-limit answer (HTTP 429, Last.fm error 29, Deezer code 4…)
//    the API is paused for a while.
//  • Counters are persisted (SharedPreferences). Each isolate (UI + the
//    background worker) only writes its own unflushed delta, merged into the
//    stored value on flush, so they never overwrite each other.
// ══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_registry.dart';

/// Read-only snapshot of one API for the UI.
class ApiStat {
  final ApiDef def;
  final int total, errors, throttled, skipped, today, lastHour;
  final int lastTs, lastStatus;
  final int windowUsed;            // calls inside the app's own ceiling window
  final int? headerLimit, headerRemaining;
  final int resetAtMs;             // when the header-announced window resets
  final int cooldownUntilMs;       // paused until (0 = not paused)

  const ApiStat({
    required this.def,
    required this.total,
    required this.errors,
    required this.throttled,
    required this.skipped,
    required this.today,
    required this.lastHour,
    required this.lastTs,
    required this.lastStatus,
    required this.windowUsed,
    required this.headerLimit,
    required this.headerRemaining,
    required this.resetAtMs,
    required this.cooldownUntilMs,
  });

  bool get paused => cooldownUntilMs > DateTime.now().millisecondsSinceEpoch;
  bool get everUsed => total > 0 || skipped > 0;
}

class _Live {
  // Unflushed deltas (this isolate only).
  int dTotal = 0, dErrors = 0, dThrottled = 0, dSkipped = 0, dToday = 0, dDay = 0;
  // Stored values as of the last load()/flush().
  int sTotal = 0, sErrors = 0, sThrottled = 0, sSkipped = 0, sToday = 0, sDay = 0;
  int lastTs = 0, lastStatus = 0;

  final List<int> hits = [];   // ceiling window (acquire time)
  final List<int> hour = [];   // calls in the last hour (this session)
  int cooldownUntil = 0;
  int? hLimit, hRemaining;
  int hResetAt = 0;

  bool get hasDelta =>
      dTotal != 0 || dErrors != 0 || dThrottled != 0 || dSkipped != 0;
}

class ApiUsage {
  ApiUsage._();

  static const _kStore = 'ls_api_usage_v1';

  static final Map<String, _Live> _live = {};
  // Last.fm key label ('user', 'builtin1'…) → [stored total, stored today,
  // stored day, delta total, delta today].
  static final Map<String, List<int>> _keys = {};

  static bool _flushScheduled = false;
  static bool _flushing = false;

  static int _now() => DateTime.now().millisecondsSinceEpoch;
  static int _day() {
    final n = DateTime.now();
    return n.year * 10000 + n.month * 100 + n.day;
  }

  static _Live _l(String id) => _live.putIfAbsent(id, () => _Live());

  // ── Rate limiter ──────────────────────────────────────────────────────────

  /// Waits for a free slot. Returns false when the wait would exceed the
  /// API's maxWaitMs (the caller must then NOT send the request).
  static Future<bool> acquire(ApiDef def) async {
    final l = _l(def.id);
    final start = _now();
    final deadline = start + (def.maxWaitMs > 0 ? def.maxWaitMs : 60000);
    while (true) {
      final now = _now();
      var wait = 0;
      if (l.cooldownUntil > now) {
        wait = l.cooldownUntil - now;
      } else if (def.headerLimits &&
          l.hRemaining != null &&
          l.hRemaining! <= 0 &&
          l.hResetAt > now) {
        wait = l.hResetAt - now;
      } else {
        final rule = def.ceiling;
        if (rule == null) return true;
        l.hits.removeWhere((t) => now - t >= rule.windowMs);
        if (l.hits.length < rule.requests) {
          l.hits.add(now);
          return true;
        }
        wait = l.hits.first + rule.windowMs - now;
      }
      if (now + wait > deadline) return false;
      await Future.delayed(Duration(milliseconds: wait < 20 ? 20 : wait + 5));
    }
  }

  /// Pauses [id] after a rate-limit answer.
  static void reportThrottled(String id, {int? retryAfterMs}) {
    final def = ApiRegistry.byId(id);
    final ms = retryAfterMs ?? def?.cooldownMs ?? 30000;
    final until = _now() + ms.clamp(1000, 15 * 60 * 1000);
    final l = _l(id);
    if (until > l.cooldownUntil) l.cooldownUntil = until;
  }

  /// Reads X-RateLimit-* headers (ListenBrainz, GitHub…).
  static void noteHeaders(String id, Map<String, String> headers) {
    final l = _l(id);
    final limit = int.tryParse(headers['x-ratelimit-limit'] ?? '');
    final remaining = int.tryParse(headers['x-ratelimit-remaining'] ?? '');
    if (limit != null) l.hLimit = limit;
    if (remaining != null) l.hRemaining = remaining;
    final resetIn = int.tryParse(headers['x-ratelimit-reset-in'] ?? '');
    final reset = int.tryParse(headers['x-ratelimit-reset'] ?? '');
    if (resetIn != null) {
      l.hResetAt = _now() + resetIn * 1000;
    } else if (reset != null) {
      // Epoch seconds (GitHub) — ignore anything that is clearly not one.
      if (reset > 1000000000) l.hResetAt = reset * 1000;
    }
  }

  // ── Recording ─────────────────────────────────────────────────────────────

  static void recordSkipped(String id) {
    final l = _l(id);
    l.dSkipped++;
    _dirty();
  }

  static void recordCall(
    String id, {
    required int status,
    bool throttled = false,
    bool error = false,
    String? keyLabel,
  }) {
    final l = _l(id);
    final now = _now();
    final day = _day();
    if (l.dDay != day) { l.dDay = day; l.dToday = 0; }
    l.dTotal++;
    l.dToday++;
    if (throttled) {
      l.dThrottled++;
    } else if (error) {
      l.dErrors++;
    }
    l.lastTs = now;
    l.lastStatus = status;
    l.hour.add(now);
    l.hour.removeWhere((t) => now - t > 3600000);
    if (keyLabel != null && keyLabel.isNotEmpty) {
      final k = _keys.putIfAbsent(keyLabel, () => [0, 0, 0, 0, 0]);
      k[3]++;
      k[4]++;
    }
    _dirty();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  static void _dirty() {
    if (_flushScheduled) return;
    _flushScheduled = true;
    Timer(const Duration(seconds: 3), () {
      _flushScheduled = false;
      flush();
    });
  }

  static Map<String, dynamic> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw);
      if (m is Map<String, dynamic>) return m;
    } catch (_) {}
    return {};
  }

  /// Loads the stored counters (call before showing them).
  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.reload();
      final root = _decode(p.getString(_kStore));
      final apis = (root['api'] as Map?)?.cast<String, dynamic>() ?? {};
      for (final e in apis.entries) {
        final m = (e.value as Map).cast<String, dynamic>();
        final l = _l(e.key);
        l.sTotal     = (m['t'] as num?)?.toInt() ?? 0;
        l.sErrors    = (m['e'] as num?)?.toInt() ?? 0;
        l.sThrottled = (m['r'] as num?)?.toInt() ?? 0;
        l.sSkipped   = (m['k'] as num?)?.toInt() ?? 0;
        l.sDay       = (m['d'] as num?)?.toInt() ?? 0;
        l.sToday     = (m['n'] as num?)?.toInt() ?? 0;
        final ls     = (m['l'] as num?)?.toInt() ?? 0;
        if (ls > l.lastTs) {
          l.lastTs = ls;
          l.lastStatus = (m['s'] as num?)?.toInt() ?? l.lastStatus;
        }
      }
      final keys = (root['keys'] as Map?)?.cast<String, dynamic>() ?? {};
      for (final e in keys.entries) {
        final m = (e.value as Map).cast<String, dynamic>();
        final k = _keys.putIfAbsent(e.key, () => [0, 0, 0, 0, 0]);
        k[0] = (m['t'] as num?)?.toInt() ?? 0;
        k[1] = (m['n'] as num?)?.toInt() ?? 0;
        k[2] = (m['d'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
  }

  /// Merges this isolate's unflushed deltas into the stored counters.
  static Future<void> flush() async {
    if (_flushing) { _dirty(); return; }
    final pending = _live.entries.where((e) => e.value.hasDelta).toList();
    final keyDelta = _keys.entries.where((e) => e.value[3] != 0).toList();
    if (pending.isEmpty && keyDelta.isEmpty) return;
    _flushing = true;
    try {
      final p = await SharedPreferences.getInstance();
      await p.reload();
      final root = _decode(p.getString(_kStore));
      final apis = (root['api'] as Map?)?.cast<String, dynamic>() ?? {};
      final keys = (root['keys'] as Map?)?.cast<String, dynamic>() ?? {};
      final today = _day();

      for (final e in pending) {
        final l = e.value;
        final m = (apis[e.key] as Map?)?.cast<String, dynamic>() ?? {};
        final day = (m['d'] as num?)?.toInt() ?? 0;
        final n = day == today ? ((m['n'] as num?)?.toInt() ?? 0) : 0;
        final t = ((m['t'] as num?)?.toInt() ?? 0) + l.dTotal;
        final er = ((m['e'] as num?)?.toInt() ?? 0) + l.dErrors;
        final r = ((m['r'] as num?)?.toInt() ?? 0) + l.dThrottled;
        final k = ((m['k'] as num?)?.toInt() ?? 0) + l.dSkipped;
        final nn = n + l.dToday;
        final storedLast = (m['l'] as num?)?.toInt() ?? 0;
        apis[e.key] = {
          't': t, 'e': er, 'r': r, 'k': k, 'd': today, 'n': nn,
          'l': l.lastTs > storedLast ? l.lastTs : storedLast,
          's': l.lastTs > storedLast ? l.lastStatus : (m['s'] ?? 0),
        };
        l.sTotal = t; l.sErrors = er; l.sThrottled = r; l.sSkipped = k;
        l.sToday = nn; l.sDay = today;
        l.dTotal = 0; l.dErrors = 0; l.dThrottled = 0; l.dSkipped = 0; l.dToday = 0;
      }

      for (final e in keyDelta) {
        final k = e.value;
        final m = (keys[e.key] as Map?)?.cast<String, dynamic>() ?? {};
        final day = (m['d'] as num?)?.toInt() ?? 0;
        final n = day == today ? ((m['n'] as num?)?.toInt() ?? 0) : 0;
        final t = ((m['t'] as num?)?.toInt() ?? 0) + k[3];
        final nn = n + k[4];
        keys[e.key] = {'t': t, 'n': nn, 'd': today};
        k[0] = t; k[1] = nn; k[2] = today; k[3] = 0; k[4] = 0;
      }

      await p.setString(_kStore, jsonEncode({'v': 1, 'api': apis, 'keys': keys}));
    } catch (_) {
      // Keep the deltas: they will be retried on the next flush.
    } finally {
      _flushing = false;
    }
  }

  static Future<void> reset() async {
    _live.clear();
    _keys.clear();
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_kStore);
    } catch (_) {}
  }

  // ── Read side (UI) ────────────────────────────────────────────────────────

  static ApiStat stat(ApiDef def) {
    final l = _l(def.id);
    final now = _now();
    final rule = def.ceiling;
    var windowUsed = 0;
    if (rule != null) {
      l.hits.removeWhere((t) => now - t >= rule.windowMs);
      windowUsed = l.hits.length;
    }
    l.hour.removeWhere((t) => now - t > 3600000);
    final today = _day();
    final storedToday = l.sDay == today ? l.sToday : 0;
    final deltaToday = l.dDay == today ? l.dToday : 0;
    final headerOk = def.headerLimits && l.hResetAt > now;
    return ApiStat(
      def: def,
      total: l.sTotal + l.dTotal,
      errors: l.sErrors + l.dErrors,
      throttled: l.sThrottled + l.dThrottled,
      skipped: l.sSkipped + l.dSkipped,
      today: storedToday + deltaToday,
      lastHour: l.hour.length,
      lastTs: l.lastTs,
      lastStatus: l.lastStatus,
      windowUsed: windowUsed,
      headerLimit: headerOk ? l.hLimit : null,
      headerRemaining: headerOk ? l.hRemaining : null,
      resetAtMs: headerOk ? l.hResetAt : 0,
      cooldownUntilMs: l.cooldownUntil > now ? l.cooldownUntil : 0,
    );
  }

  /// Requests made with a given Last.fm key label: (total, today).
  static (int, int) keyUsage(String label) {
    final k = _keys[label];
    if (k == null) return (0, 0);
    final today = _day();
    final storedToday = k[2] == today ? k[1] : 0;
    return (k[0] + k[3], storedToday + k[4]);
  }
}
