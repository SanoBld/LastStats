// lib/screens/settings/api_page.dart
// Settings → API: every external service the app uses, its documented limit,
// the ceiling the app imposes on itself, and live consumption.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/l10n.dart';
import '../../services/api_registry.dart';
import '../../services/api_usage.dart';
import '../../services/internal_keys.dart';
import '../../services/storage_manager.dart';
import '../../widgets/m3_components.dart';
import '../../widgets/skeleton.dart';
import 'settings_helpers.dart';
import 'settings_rows.dart';

class ApiPage extends StatefulWidget {
  const ApiPage({super.key});

  @override
  State<ApiPage> createState() => _ApiPageState();
}

enum _Status { idle, ok, near, paused }

class _ApiPageState extends State<ApiPage> {
  Timer? _timer;
  bool _loading = true;
  int _tick = 0;
  int _lastfmStored = 0;
  String _userKey = '';
  bool _backupOn = false;

  @override
  void initState() {
    super.initState();
    ApiUsage.loadSettings().then((_) { if (mounted) setState(() {}); });
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ApiUsage.load();
    final p = await SharedPreferences.getInstance();
    final key = p.getString('ls_apikey') ?? '';
    final backup = await InternalKeys.isFallbackEnabled(p);
    var stored = _lastfmStored;
    // Disk scan is heavier: first time, then about every 15 s.
    if (_tick % 5 == 0) {
      try {
        final s = await StorageManager.getStats();
        stored = s.scrobbleBytes + s.apiBytes;
      } catch (_) {}
    }
    _tick++;
    if (!mounted) return;
    setState(() {
      _userKey = key;
      _backupOn = backup;
      _lastfmStored = stored;
      _loading = false;
    });
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  String _win(int ms) {
    final s = (ms / 1000).round();
    if (s == 1) return L.apiWinSecond;
    if (s == 60) return L.apiWinMinute;
    if (s == 3600) return L.apiWinHour;
    return L.apiWinSeconds(s);
  }

  String _limit(ApiRule r) => L.apiLimitPer(r.requests, _win(r.windowMs));

  String _dur(int ms) {
    final s = (ms / 1000).ceil();
    if (s < 60) return '${s}s';
    if (s < 3600) return '${(s / 60).ceil()}m';
    return '${(s / 3600).ceil()}h';
  }

  String _when(int ts) {
    if (ts <= 0) return L.apiNever;
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    String two(int n) => n.toString().padLeft(2, '0');
    final now = DateTime.now();
    final time = '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
    if (d.year == now.year && d.month == now.month && d.day == now.day) return time;
    return '${two(d.day)}/${two(d.month)} $time';
  }

  String _cat(ApiCategory c) => switch (c) {
        ApiCategory.listening => L.apiCatListening,
        ApiCategory.metadata  => L.apiCatMetadata,
        ApiCategory.artwork   => L.apiCatArtwork,
        ApiCategory.lyrics    => L.apiCatLyrics,
        ApiCategory.translate => L.apiCatTranslate,
        ApiCategory.updates   => L.apiCatUpdates,
        ApiCategory.other     => L.apiCatOther,
      };

  /// 0..1 usage of the limit that matters most right now, or null.
  double? _fraction(ApiStat s) {
    if (s.headerLimit != null && s.headerRemaining != null && s.headerLimit! > 0) {
      return ((s.headerLimit! - s.headerRemaining!) / s.headerLimit!).clamp(0.0, 1.0);
    }
    final c = s.def.ceiling;
    if (c != null && c.requests > 0) {
      return (s.windowUsed / c.requests).clamp(0.0, 1.0);
    }
    return null;
  }

  _Status _status(ApiStat s) {
    if (s.paused) return _Status.paused;
    if (!s.everUsed) return _Status.idle;
    final f = _fraction(s);
    if (f != null && f >= 0.8) return _Status.near;
    return _Status.ok;
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (_loading) {
      return Scaffold(
        appBar: M3AppBar(title: L.apiTitle),
        body: const SkeletonList(),
      );
    }

    final defs = [...ApiRegistry.all, ApiRegistry.cdn];
    final stats = {for (final d in defs) d.id: ApiUsage.stat(d)};
    final today = stats.values.fold<int>(0, (a, s) => a + s.today);
    final errors = stats.values.fold<int>(0, (a, s) => a + s.errors);
    final limited = stats.values.fold<int>(0, (a, s) => a + s.throttled);

    const order = [
      ApiCategory.listening, ApiCategory.metadata, ApiCategory.artwork,
      ApiCategory.lyrics, ApiCategory.translate, ApiCategory.updates,
      ApiCategory.other,
    ];

    return Scaffold(
      appBar: M3AppBar(title: L.apiTitle),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _summary(scheme, text, today, errors, limited),
                const SizedBox(height: 12),
                SettingsSection(
                  label: L.apiTitle,
                  children: [
                    SettingSwitchRow(
                      icon: Icons.speed_rounded,
                      title: L.apiLimiter,
                      subtitle: L.apiLimiterSub,
                      value: ApiUsage.limiterEnabled,
                      onChanged: (v) async {
                        await ApiUsage.setLimiter(v);
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
                Text(L.apiIntro,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                for (final cat in order) ...[
                  if (stats.values.any((s) => s.def.category == cat)) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                      child: Text(_cat(cat),
                          style: text.titleSmall?.copyWith(
                              color: scheme.primary, fontWeight: FontWeight.w700)),
                    ),
                    for (final s in stats.values.where((s) => s.def.category == cat))
                      _tile(scheme, text, s),
                  ],
                ],
                const SizedBox(height: 24),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _confirmReset,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(L.apiReset),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary(ColorScheme scheme, TextTheme text, int today, int errors, int limited) {
    Widget cell(String label, int value, Color color) => Expanded(
          child: Column(children: [
            Text('$value',
                style: text.headlineSmall?.copyWith(
                    color: color, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: text.labelSmall?.copyWith(color: scheme.onPrimaryContainer)),
          ]),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(children: [
        cell(L.apiSumToday, today, scheme.onPrimaryContainer),
        cell(L.apiSumErrors, errors,
            errors > 0 ? scheme.error : scheme.onPrimaryContainer),
        cell(L.apiSumLimited, limited,
            limited > 0 ? scheme.error : scheme.onPrimaryContainer),
      ]),
    );
  }

  Widget _tile(ColorScheme scheme, TextTheme text, ApiStat s) {
    final st = _status(s);
    final (label, color) = switch (st) {
      _Status.idle   => (L.apiStatusIdle, scheme.onSurfaceVariant),
      _Status.ok     => (L.apiStatusOk, scheme.primary),
      _Status.near   => (L.apiStatusNear, scheme.tertiary),
      _Status.paused => (L.apiStatusPaused, scheme.error),
    };
    final frac = _fraction(s);
    final isLastfm = s.def.id == 'lastfm';

    Widget row(String k, String v, {Color? vColor}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Text(k,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
            const SizedBox(width: 12),
            Flexible(
                child: Text(v,
                    textAlign: TextAlign.end,
                    style: text.bodySmall?.copyWith(
                        color: vColor ?? scheme.onSurface,
                        fontWeight: FontWeight.w600))),
          ]),
        );

    final details = <Widget>[
      row(L.apiProviderLimit,
          s.def.official != null ? _limit(s.def.official!) : L.apiNoLimit),
      if (s.def.ceiling != null) row(L.apiAppCeiling, _limit(s.def.ceiling!)),
      if (s.headerLimit != null && s.headerRemaining != null) ...[
        row(L.apiRemaining, '${s.headerRemaining} / ${s.headerLimit}'),
        if (s.resetAtMs > 0)
          row(L.apiResetsIn(_dur(
              s.resetAtMs - DateTime.now().millisecondsSinceEpoch)), ''),
      ] else if (s.def.ceiling != null)
        row(L.apiWindowUsage, '${s.windowUsed} / ${s.def.ceiling!.requests}'),
      if (s.paused)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            L.apiPausedFor(_dur(
                s.cooldownUntilMs - DateTime.now().millisecondsSinceEpoch)),
            style: text.bodySmall?.copyWith(color: scheme.error),
          ),
        ),
      const Divider(height: 20),
      row(L.apiToday, '${s.today}'),
      row(L.apiLastHour, '${s.lastHour}'),
      row(L.apiTotal, '${s.total}'),
      row(L.apiSumErrors, '${s.errors}',
          vColor: s.errors > 0 ? scheme.error : null),
      row(L.apiRateLimited, '${s.throttled}',
          vColor: s.throttled > 0 ? scheme.error : null),
      row(L.apiSkipped, '${s.skipped}'),
      row(L.apiLastCall,
          s.lastTs > 0 ? '${_when(s.lastTs)} · ${s.lastStatus}' : L.apiNever),
      const SizedBox(height: 6),
      if (isLastfm) ..._lastfmExtras(scheme, text, row)
      else
        Text(
          s.def.sharedKey ? L.apiSharedKey : L.apiNoKey,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      if (s.def.unofficial)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(L.apiUnofficial,
              style: text.bodySmall?.copyWith(color: scheme.tertiary)),
        ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('api_${s.def.id}'),
          initiallyExpanded: isLastfm,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(s.def.name,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${L.apiToday}: ${s.today}  ·  $label',
                  style: text.bodySmall?.copyWith(color: color)),
              if (frac != null) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: frac,
                    minHeight: 5,
                    color: frac >= 0.8 ? scheme.tertiary : scheme.primary,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ]),
          ),
          children: details,
        ),
      ),
    );
  }

  List<Widget> _lastfmExtras(ColorScheme scheme, TextTheme text,
      Widget Function(String, String, {Color? vColor}) row) {
    final idx = InternalKeys.indexOf(_userKey);
    final keyText = idx >= 0
        ? L.apiBuiltinKey(idx + 1, InternalKeys.poolSize)
        : L.apiOwnKey;

    final labels = <String>['user', for (var i = 1; i <= InternalKeys.poolSize; i++) 'builtin$i'];
    final perKey = <Widget>[];
    for (final l in labels) {
      final (total, today) = ApiUsage.keyUsage(l);
      if (total == 0) continue;
      final name = l == 'user'
          ? L.apiOwnKey
          : L.apiBuiltinKey(int.parse(l.substring(7)), InternalKeys.poolSize);
      perKey.add(row(name, '$today / $total'));
    }

    final cap = ApiRegistry.lastfmStorageCapBytes;
    final over = _lastfmStored > cap;

    return [
      row(L.apiKeyInUse, keyText),
      row(_backupOn ? L.apiBackupOn : L.apiBackupOff, ''),
      if (perKey.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(L.apiPerKey,
            style: text.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
        ...perKey,
      ],
      const SizedBox(height: 10),
      row(L.apiStorageTitle,
          L.apiStorageValue(StorageManager.formatBytes(_lastfmStored),
              StorageManager.formatBytes(cap)),
          vColor: over ? scheme.error : null),
      if (over)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(L.apiStorageOver,
              style: text.bodySmall?.copyWith(color: scheme.error)),
        ),
      const SizedBox(height: 10),
      Text(L.apiLastfmNote,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
    ];
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(L.apiReset),
            content: Text(L.apiResetBody),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(L.commonCancel)),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(L.apiReset)),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await ApiUsage.reset();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(L.apiResetDone)));
  }
}
