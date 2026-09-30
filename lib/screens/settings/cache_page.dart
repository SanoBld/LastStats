// lib/screens/settings/cache_page.dart
import 'package:flutter/material.dart';
import 'settings_helpers.dart';
import 'settings_rows.dart';
import '../../theme/m3_shapes.dart';
import '../../theme/m3_motion.dart';
import '../../widgets/skeleton.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/storage_manager.dart';
import '../../services/data_cache.dart';
import '../../services/scrobbles_file_cache.dart';
import '../../services/image_service.dart';
import '../../l10n/l10n.dart';
import '../../l10n/extra_strings.dart';
import '../../widgets/m3_components.dart';
import '../../widgets/motion_artwork_video.dart';
import '../../services/motion_artwork_service.dart';
import '../../services/video_disk_cache.dart';

// Photo cache limit presets in bytes. 0 = unlimited.
const _limits = [
  (label: '100 MB', bytes: 100 * 1024 * 1024),
  (label: '250 MB', bytes: 250 * 1024 * 1024),
  (label: '500 MB', bytes: 500 * 1024 * 1024),
  (label: '1 GB',   bytes: 1024 * 1024 * 1024),
  (label: '2 GB',   bytes: 2 * 1024 * 1024 * 1024),
  (label: '5 GB',   bytes: 5 * 1024 * 1024 * 1024),
  (label: '∞',      bytes: 0),
];

// Video cache presets: -1 = off, 0 = unlimited.
const _videoLimits = [
  (label: '', bytes: -1), // label comes from tx('cache_video_off')
  (label: '100 MB', bytes: 100 * 1024 * 1024),
  (label: '250 MB', bytes: 250 * 1024 * 1024),
  (label: '500 MB', bytes: 500 * 1024 * 1024),
  (label: '1 GB',   bytes: 1024 * 1024 * 1024),
  (label: '2 GB',   bytes: 2 * 1024 * 1024 * 1024),
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

  Future<void> _setVideoLimit(int bytes) async {
    await StorageManager.setVideoMaxBytes(bytes);
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

  Future<void> _releaseVideo() async {
    setState(() => _clearing = true);
    await MotionArtworkVideo.releaseAll();
    MotionArtworkService.clearMemory();
    await _loadStats();
    if (!mounted) return;
    setState(() => _clearing = false);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tx('cache_video_cleared'))));
  }

  Future<void> _clearVideoDisk() async {
    setState(() => _clearing = true);
    await VideoDiskCache.clear();
    await _loadStats();
    if (mounted) setState(() => _clearing = false);
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
    await VideoDiskCache.clear();
    MotionArtworkService.clearMemory();
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
      appBar: M3AppBar(title: L.cacheTitle),
      body: SafeArea(top: false, 
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(children: [
Expanded(
                child: _loading
          ? const SkeletonList()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: [
                // ── Usage overview ─────────────────────────────────────────
                _UsageCard(stats: _stats!, scheme: scheme, text: text),

                const SizedBox(height: 20),

                // ── Memory: animated covers (Apple Music video) ────────────
                SettingsSection(label: tx('cache_memory_section'), children: [
                  if (_clearing)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: M3LoadingIndicator()),
                    )
                  else
                    SettingActionRow(
                      icon: Icons.movie_filter_rounded,
                      title: tx('cache_video_t'),
                      subtitle: tx('cache_video_s', {
                        'mem': StorageManager.formatBytes(MotionArtworkVideo.liveBytes),
                        'players': '${MotionArtworkVideo.liveCount}',
                        'links': '${MotionArtworkService.cachedLinks}',
                      }),
                      onTap: _releaseVideo,
                    ),
                ]),

                const SizedBox(height: 20),

                // ── Storage limit + offline mode ────────────────────────────
                SettingsSection(label: tx('cache_storage_section'), children: [
                  SettingChoiceRow(
                    icon: Icons.photo_library_rounded,
                    title: tx('cache_img_limit_t'),
                    options: [for (final l in _limits) ('${l.bytes}', l.label, null)],
                    value: '${StorageManager.maxBytes}',
                    description: tx('cache_img_limit_s'),
                    onChanged: (v) => _setLimit(int.parse(v)),
                  ),
                  SettingChoiceRow(
                    icon: Icons.movie_filter_rounded,
                    title: tx('cache_vid_limit_t'),
                    options: [
                      for (final l in _videoLimits)
                        ('${l.bytes}',
                         l.bytes < 0 ? tx('cache_video_off') : l.label, null),
                    ],
                    value: '${StorageManager.videoMaxBytes}',
                    description: tx('cache_vid_limit_s'),
                    onChanged: (v) => _setVideoLimit(int.parse(v)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Text(tx('cache_no_limit_note'),
                        style: text.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                  _OfflineModeCard(scheme: scheme, text: text),
                ]),

                const SizedBox(height: 20),

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
                      icon: Icons.movie_filter_rounded,
                      title: tx('cache_vid_disk_t'),
                      subtitle: tx('cache_vid_disk_s', {
                        'size': StorageManager.formatBytes(_stats!.videoBytes),
                      }),
                      onTap: _clearVideoDisk,
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
                      danger: true,
                      onTap: _clearAll,
                    ),
                  ],
                ]),

                const SizedBox(height: 32),
              ],
            ),
              ),
            ]),
          ),
        ),
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
    final totalStr = StorageManager.formatBytes(total);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        scheme.primaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          M3CookieBadge(
            size: 52,
            color: scheme.primary,
            child: Icon(Icons.storage_rounded, color: scheme.onPrimary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(L.cacheTotalUsed,
                style: text.labelLarge?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.8))),
            Text(totalStr,
                style: text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer)),
          ])),
        ]),
        const SizedBox(height: 18),
        _Bar(label: L.cacheImages, bytes: stats.imageBytes, total: total,
            limit: stats.maxBytes,
            color: scheme.primary, scheme: scheme, text: text),
        const SizedBox(height: 8),
        _Bar(label: tx('cache_video_short'), bytes: stats.videoBytes, total: total,
            limit: stats.videoMaxBytes,
            color: scheme.error, scheme: scheme, text: text),
        const SizedBox(height: 8),
        _Bar(label: L.cacheApiData, bytes: stats.apiBytes, total: total,
            color: scheme.secondary, scheme: scheme, text: text),
        const SizedBox(height: 8),
        _Bar(label: L.cacheScrobblesShort, bytes: stats.scrobbleBytes, total: total,
            color: scheme.tertiary, scheme: scheme, text: text),
      ]),
    );
  }
}

class _Bar extends StatelessWidget {
  final String      label;
  final int         bytes;
  final int         total;
  final int         limit; // >0: bar shows bytes / limit, else share of total
  final Color       color;
  final ColorScheme scheme;
  final TextTheme   text;

  const _Bar({
    required this.label,
    required this.bytes,
    required this.total,
    this.limit = 0,
    required this.color,
    required this.scheme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final frac = limit > 0
        ? (bytes / limit).clamp(0.0, 1.0)
        : (total > 0 ? bytes / total : 0.0);

    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: text.bodySmall?.copyWith(color: scheme.onPrimaryContainer))),
      const SizedBox(width: 8),
      SizedBox(
        width: 100,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value:           frac,
            minHeight:       4,
            color:           color,
            backgroundColor: scheme.onPrimaryContainer.withValues(alpha: 0.15),
          ),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: limit > 0 ? 112 : 60,
        child: Text(
          limit > 0
              ? '${StorageManager.formatBytes(bytes)} / ${StorageManager.formatBytes(limit)}'
              : StorageManager.formatBytes(bytes),
          style:     text.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
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
