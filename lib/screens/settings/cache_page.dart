// lib/screens/settings/cache_page.dart
import 'package:flutter/material.dart';
import 'settings_helpers.dart';
import 'settings_rows.dart';
import '../../widgets/m3_components.dart';
import '../../theme/m3_motion.dart';
import '../../theme/m3_shapes.dart';
import '../../widgets/skeleton.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/storage_manager.dart';
import '../../services/data_cache.dart';
import '../../services/scrobbles_file_cache.dart';
import '../../services/image_service.dart';
import '../../l10n/l10n.dart';

// Storage limit presets in bytes. 0 = unlimited.
const _limits = [
  (label: '100 MB', bytes: 100 * 1024 * 1024),
  (label: '250 MB', bytes: 250 * 1024 * 1024),
  (label: '500 MB', bytes: 500 * 1024 * 1024),
  (label: '1 GB',   bytes: 1024 * 1024 * 1024),
  (label: '2 GB',   bytes: 2 * 1024 * 1024 * 1024),
  (label: '5 GB',   bytes: 5 * 1024 * 1024 * 1024),
  (label: '∞',      bytes: 0),
];

class CachePage extends StatefulWidget {
  const CachePage({super.key});

  @override
  State<CachePage> createState() => _CachePageState();
}

class _CachePageState extends State<CachePage> {
  StorageStats? _stats;
  bool _loading    = true;
  bool _clearing   = false;


  @override
  void initState() {
    super.initState();
    _loadStats(showSpinner: true);
  }

  Future<void> _loadStats({bool showSpinner = false}) async {
    if (showSpinner) setState(() => _loading = true);
    await StorageManager.init();
    final stats = await StorageManager.getStats();
    if (mounted) setState(() { _stats = stats; _loading = false; });
  }

  // ── Storage limit picker ──────────────────────────────────────────────────

  Future<void> _setLimit(int bytes) async {
    await StorageManager.setMaxBytes(bytes);
    if (bytes > 0) await StorageManager.enforceQuota();
    await _loadStats();
  }

  // ── Clear actions ─────────────────────────────────────────────────────────

  Future<void> _clearImages() async {
    setState(() => _clearing = true);
    await ImageService.clearAllCache();
    await _loadStats();
    setState(() => _clearing = false);
  }

  Future<void> _clearApiCache() async {
    setState(() => _clearing = true);
    await DataCache.clear();
    await _loadStats();
    setState(() => _clearing = false);
  }

  Future<void> _clearScrobbles() async {
    final confirmed = await _confirm(
      L.cacheConfirmScrobblesTitle,
      L.cacheConfirmScrobblesBody,
    );
    if (!confirmed) return;
    setState(() => _clearing = true);
    await ScrobblesFileCache.clear();
    await _loadStats();
    setState(() => _clearing = false);
  }

  Future<void> _clearAll() async {
    final confirmed = await _confirm(
      L.cacheConfirmAllTitle,
      L.cacheConfirmAllBody,
    );
    if (!confirmed) return;
    setState(() => _clearing = true);
    await ImageService.clearAllCache();
    await DataCache.clear();
    await ScrobblesFileCache.clear();
    await _loadStats();
    setState(() => _clearing = false);
  }

  Future<bool> _confirm(String title, String body) async {
    return await showDialog<bool>(
    animationStyle: kM3DialogAnimation,
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(L.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(L.cacheDelete),
          ),
        ],
      ),
    ) ?? false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(L.cacheTitle),
        scrolledUnderElevation: 0,
      ),
      body: _loading
          ? const SkeletonList()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Usage overview ─────────────────────────────────────────
                SettingsSection(label: L.cacheUsage, children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _UsageCard(stats: _stats!, scheme: scheme, text: text),
                  ),
                ]),

                const SizedBox(height: 16),

                // ── Storage limit + offline mode ────────────────────────────
                SettingsSection(label: L.cacheLimit, children: [
                  SettingChoiceRow(
                    icon: Icons.storage_rounded,
                    title: L.cacheLimit,
                    options: [for (final l in _limits) ('${l.bytes}', l.label, null)],
                    value: '${StorageManager.maxBytes}',
                    description: L.cacheLimitHint,
                    onChanged: (v) => _setLimit(int.parse(v)),
                  ),
                  _OfflineModeCard(scheme: scheme, text: text),
                ]),

                const SizedBox(height: 16),

                // ── Clear categories ───────────────────────────────────────
                SettingsSection(label: L.cacheClearSection, children: [
                  if (_clearing)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: M3LoadingIndicator()),
                    )
                  else ...[
                    SettingActionRow(
                      icon: Icons.image_outlined,
                      title: L.cacheImages,
                      subtitle: '${StorageManager.formatBytes(_stats!.imageBytes)} · ${L.cacheImagesSubtitle}',
                      onTap: _clearImages,
                    ),
                    SettingActionRow(
                      icon: Icons.api_outlined,
                      title: L.cacheApiData,
                      subtitle: '${StorageManager.formatBytes(_stats!.apiBytes)} · ${L.cacheApiDataSubtitle}',
                      onTap: _clearApiCache,
                    ),
                    SettingActionRow(
                      icon: Icons.history_rounded,
                      title: L.cacheScrobbles,
                      subtitle: '${StorageManager.formatBytes(_stats!.scrobbleBytes)} · ${L.cacheScrobblesSubtitle}',
                      onTap: _clearScrobbles,
                    ),
                    SettingActionRow(
                      icon: Icons.delete_sweep_rounded,
                      title: L.cacheClearBtn,
                      onTap: _clearAll,
                    ),
                  ],
                ]),

                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

// ── Usage card ────────────────────────────────────────────────────────────────

class _UsageCard extends StatelessWidget {
  final StorageStats stats;
  final ColorScheme  scheme;
  final TextTheme    text;

  const _UsageCard({
    required this.stats,
    required this.scheme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final total     = stats.totalBytes;
    final max       = stats.maxBytes;
    final unlimited = max <= 0;
    final fraction  = stats.usedFraction;

    final totalStr = StorageManager.formatBytes(total);
    final maxStr   = unlimited
        ? L.cacheUnlimited
        : StorageManager.formatBytes(max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(children: [
        // Total usage row
        Row(children: [
          Icon(Icons.storage_rounded, color: scheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(
            L.cacheTotalUsed,
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          )),
          Text(
            '$totalStr / $maxStr',
            style: text.bodyMedium?.copyWith(
              color:      scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ]),

        const SizedBox(height: 12),

        // Progress bar
        if (!unlimited) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:            fraction,
              minHeight:        8,
              color:            fraction > 0.9 ? scheme.error : scheme.primary,
              backgroundColor:  scheme.surfaceContainerLowest,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Per-category breakdown
        _Bar(
          label:   L.cacheImages,
          bytes:   stats.imageBytes,
          total:   total,
          color:   scheme.primary,
          scheme:  scheme,
          text:    text,
        ),
        const SizedBox(height: 6),
        _Bar(
          label:  L.cacheApiData,
          bytes:  stats.apiBytes,
          total:  total,
          color:  scheme.secondary,
          scheme: scheme,
          text:   text,
        ),
        const SizedBox(height: 6),
        _Bar(
          label:  L.cacheScrobblesShort,
          bytes:  stats.scrobbleBytes,
          total:  total,
          color:  scheme.tertiary,
          scheme: scheme,
          text:   text,
        ),
      ]),
    );
  }
}

class _Bar extends StatelessWidget {
  final String      label;
  final int         bytes;
  final int         total;
  final Color       color;
  final ColorScheme scheme;
  final TextTheme   text;

  const _Bar({
    required this.label,
    required this.bytes,
    required this.total,
    required this.color,
    required this.scheme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final frac = total > 0 ? bytes / total : 0.0;

    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
      const SizedBox(width: 8),
      SizedBox(
        width: 100,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value:           frac,
            minHeight:       4,
            color:           color,
            backgroundColor: scheme.surfaceContainerLowest,
          ),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 60,
        child: Text(
          StorageManager.formatBytes(bytes),
          style:     text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.end,
        ),
      ),
    ]);
  }
}

// ── Offline mode toggle ───────────────────────────────────────────────────────

class _OfflineModeCard extends StatefulWidget {
  final ColorScheme scheme;
  final TextTheme   text;

  const _OfflineModeCard({
    required this.scheme,
    required this.text,
  });

  @override
  State<_OfflineModeCard> createState() => _OfflineModeCardState();
}

class _OfflineModeCardState extends State<_OfflineModeCard> {
  bool _keepStale = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(() {
        _keepStale = p.getBool('ls_cache_serve_stale') ?? true;
      });
      }
    });
  }

  Future<void> _toggle(bool v) async {
    setState(() => _keepStale = v);
    DataCache.offlineMode = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('ls_cache_serve_stale', v);
  }

  @override
  Widget build(BuildContext context) => SettingSwitchRow(
        icon: Icons.cloud_off_rounded,
        title: L.cacheOfflineTitle,
        subtitle: L.cacheOfflineSubtitle,
        value: _keepStale,
        onChanged: _toggle,
      );
}
