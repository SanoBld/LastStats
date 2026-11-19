// lib/services/source_switch.dart
// Switching Last.fm <-> ListenBrainz while local scrobbles exist.
//   transfer (to ListenBrainz): POST /1/submit-listens (type "import"), keep local copy
//   merge: keep old data + download the new service, union; Last.fm wins on conflict
//   fresh: wipe local data
// Nothing is deleted unless the user picks "fresh".
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/extra_strings.dart';
import '../theme/m3_shapes.dart';
import 'all_scrobbles_service.dart';
import 'api_http.dart';
import 'data_cache.dart';
import 'lastfm_service.dart';
import 'scrobbles_file_cache.dart';

enum SwitchChoice { transfer, merge, fresh }

class SourceSwitch {
  SourceSwitch._();

  static const _kCacheSource = 'ls_cache_source'; // 'lfm' | 'lb'
  static const _kOwner       = 'ls_cache_owner';  // same key as CacheOwner
  static const _lbMinTs      = 1033430400;        // ListenBrainz minimum (2002-10-01)

  static Future<void> _mark(bool lb) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCacheSource, lb ? 'lb' : 'lfm');
  }

  /// Call after a successful login, credentials saved and DataSource switched.
  /// [fromLb] = service active BEFORE the switch. [apiKey] = Last.fm key or LB token.
  static Future<void> handle(
    BuildContext context, {
    required bool fromLb,
    required bool toLb,
    required String username,
    required String apiKey,
  }) async {
    final p = await SharedPreferences.getInstance();
    await ScrobblesFileCache.init();
    final marker  = p.getString(_kCacheSource);
    final cacheLb = marker != null ? marker == 'lb' : fromLb;
    final count   = ScrobblesFileCache.getTotalScrobbleCount();

    if (count == 0 || cacheLb == toLb) {
      await _mark(toLb);
      return;
    }
    if (!context.mounted) return;
    final choice = await _ask(context, count, toLb);
    if (choice == null || !context.mounted) return;

    switch (choice) {
      case SwitchChoice.fresh:
        await ScrobblesFileCache.clear();
      case SwitchChoice.transfer:
        await _transfer(context, apiKey);
      case SwitchChoice.merge:
        await _merge(context, oldIsLfm: !cacheLb, username: username, apiKey: apiKey);
    }
    await DataCache.clear(); // old-service API data must not be shown any more
    await p.setString(_kOwner, username.trim().toLowerCase()); // keep data we just kept
    await _mark(toLb);
  }

  static Future<SwitchChoice?> _ask(BuildContext context, int count, bool toLb) {
    return showDialog<SwitchChoice>(
      context: context,
      barrierDismissible: false,
      animationStyle: kM3DialogAnimation,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        Widget opt(IconData icon, String t, String s, SwitchChoice c) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: scheme.primary),
              title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(s),
              onTap: () => Navigator.pop(ctx, c),
            );
        return AlertDialog(
          title: Text(tx('sw_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx('sw_body', {'n': '$count'})),
                const SizedBox(height: 8),
                if (toLb)
                  opt(Icons.upload_rounded, tx('sw_transfer'), tx('sw_transfer_s'),
                      SwitchChoice.transfer),
                opt(Icons.merge_type_rounded, tx('sw_merge'), tx('sw_merge_s'),
                    SwitchChoice.merge),
                opt(Icons.delete_sweep_rounded, tx('sw_fresh'), tx('sw_fresh_s'),
                    SwitchChoice.fresh),
              ],
            ),
          ),
        );
      },
    );
  }

  static ValueNotifier<String> _openBusy(BuildContext context, String first) {
    final msg = ValueNotifier<String>(first);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(children: [
            const SizedBox(
                width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(width: 16),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: msg,
                builder: (_, v, _) => Text(v),
              ),
            ),
          ]),
        ),
      ),
    );
    return msg;
  }

  static void _closeBusy(BuildContext context) {
    if (context.mounted) Navigator.of(context).pop();
  }

  static Future<void> _info(BuildContext context, String text) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(text),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(tx('sw_ok'))),
          ],
        ),
      );

  // ── Transfer to ListenBrainz ──────────────────────────────────────────
  static Future<void> _transfer(BuildContext context, String token) async {
    final msg = _openBusy(context, tx('sw_sending', {'done': '0', 'total': '…'}));
    var ok = true;
    try {
      final all = <ScrobbleRecord>[];
      for (final y in ScrobblesFileCache.getCachedYears()) {
        all.addAll(ScrobblesFileCache.getRecords(y) ?? const <ScrobbleRecord>[]);
      }
      await _submit(all, token, (d, t) {
        msg.value = tx('sw_sending', {'done': '$d', 'total': '$t'});
      });
    } catch (_) {
      ok = false;
    }
    _closeBusy(context);
    if (!ok && context.mounted) await _info(context, tx('sw_fail'));
  }

  static Future<void> _submit(List<ScrobbleRecord> records, String token,
      void Function(int done, int total) onProgress) async {
    final list = records.where((r) => r.hasMetadata && r.ts >= _lbMinTs).toList()
      ..sort((a, b) => a.ts.compareTo(b.ts));
    const batch = 500;
    final uri = Uri.https('api.listenbrainz.org', '/1/submit-listens');
    var done = 0;
    for (var i = 0; i < list.length; i += batch) {
      final chunk = list.sublist(i, math.min(i + batch, list.length));
      final body = jsonEncode({
        'listen_type': 'import',
        'payload': [
          for (final r in chunk)
            {
              'listened_at': r.ts,
              'track_metadata': {
                'artist_name': r.artist,
                'track_name': r.track,
                if (r.album.isNotEmpty) 'release_name': r.album,
              },
            },
        ],
      });
      var attempts = 0;
      while (true) {
        final res = await ApiHttp.post(
          uri,
          headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
          body: body,
        ).timeout(const Duration(seconds: 60));
        if (res.statusCode == 200) break;
        if (res.statusCode == 429 && attempts < 6) {
          final wait = int.tryParse(res.headers['x-ratelimit-reset-in'] ?? '') ?? 10;
          await Future.delayed(Duration(seconds: wait.clamp(1, 60)));
          attempts++;
          continue;
        }
        throw Exception('HTTP ${res.statusCode}');
      }
      done += chunk.length;
      onProgress(done, list.length);
    }
  }

  // ── Merge ─────────────────────────────────────────────────────────────
  static Future<void> _merge(BuildContext context,
      {required bool oldIsLfm, required String username, required String apiKey}) async {
    final msg = _openBusy(context, tx('sw_merging', {'year': '…'}));
    try {
      final old = <int, List<ScrobbleRecord>>{
        for (final y in ScrobblesFileCache.getCachedYears())
          y: List<ScrobbleRecord>.of(
              ScrobblesFileCache.getRecords(y) ?? const <ScrobbleRecord>[]),
      };
      final service = LastFmService(apiKey: apiKey, username: username);
      final nowYear = DateTime.now().year;
      var start = old.isEmpty ? nowYear : old.keys.reduce(math.min);
      try {
        final info = await service.getUserInfo();
        final uts = int.tryParse('${info?['registered']?['unixtime'] ?? ''}');
        if (uts != null && uts > 0) {
          start = math.min(start, DateTime.fromMillisecondsSinceEpoch(uts * 1000).year);
        }
      } catch (_) {}

      for (var y = start; y <= nowYear; y++) {
        msg.value = tx('sw_merging', {'year': '$y'});
        await AllScrobblesService.loadYear(y, service, force: true);
        final prev = old[y] ?? const <ScrobbleRecord>[];
        if (prev.isEmpty) continue;
        final fresh = ScrobblesFileCache.getRecords(y) ?? const <ScrobbleRecord>[];
        // Last.fm entries first so they win conflicts.
        final merged = oldIsLfm ? _union(prev, fresh) : _union(fresh, prev);
        await ScrobblesFileCache.setYear(y, merged,
            complete: ScrobblesFileCache.isYearComplete(y));
      }
    } catch (_) {
      // Old data stays (per-year union above).
    }
    _closeBusy(context);
  }

  static String _key(ScrobbleRecord r) =>
      '${r.artist.trim().toLowerCase()}|${r.track.trim().toLowerCase()}';

  /// All of [lfm] plus the [lb] records that are not duplicates. Sorted by ts.
  static List<ScrobbleRecord> _union(List<ScrobbleRecord> lfm, List<ScrobbleRecord> lb) {
    final out   = List<ScrobbleRecord>.of(lfm);
    final tsSet = <int>{};
    final byKey = <String, List<int>>{};
    for (final r in lfm) {
      tsSet.add(r.ts);
      (byKey[_key(r)] ??= <int>[]).add(r.ts);
    }
    for (final r in lb) {
      if (tsSet.contains(r.ts)) continue;
      final same = byKey[_key(r)];
      if (same != null && same.any((t) => (t - r.ts).abs() <= 30)) continue;
      out.add(r);
    }
    out.sort((a, b) => a.ts.compareTo(b.ts));
    return out;
  }
}
