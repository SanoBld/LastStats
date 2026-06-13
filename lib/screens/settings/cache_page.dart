// lib/screens/settings/cache_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/storage_manager.dart';
import '../../services/offline_image_cache.dart';
import '../../services/data_cache.dart';
import '../../services/scrobbles_file_cache.dart';
import '../../services/image_service.dart';
import '../../app_state.dart';

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

  bool get _isEn => localeNotifier.value == 'en';
  String _t(String fr, String en) => _isEn ? en : fr;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    await StorageManager.init();
    final stats = await StorageManager.getStats();
    if (mounted) setState(() { _stats = stats; _loading = false; });
  }

  // ── Storage limit picker ──────────────────────────────────────────────────

  int _selectedLimitBytes() {
    final cur = StorageManager.maxBytes;
    for (final p in _limits) {
      if (p.bytes == cur) return cur;
    }
    return StorageStats(imageBytes: 0, scrobbleBytes: 0, apiBytes: 0, maxBytes: cur).maxBytes;
  }

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
      _t('Supprimer l\'historique ?', 'Clear scrobble history?'),
      _t(
        'L\'historique complet sera supprimé. Il sera rechargé au prochain démarrage.',
        'The full history will be deleted and re-downloaded on next launch.',
      ),
    );
    if (!confirmed) return;
    setState(() => _clearing = true);
    await ScrobblesFileCache.clear();
    await _loadStats();
    setState(() => _clearing = false);
  }

  Future<void> _clearAll() async {
    final confirmed = await _confirm(
      _t('Vider tout le cache ?', 'Clear all cache?'),
      _t(
        'Images, données API et historique seront supprimés.',
        'Images, API data and scrobble history will all be deleted.',
      ),
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
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('Annuler', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t('Supprimer', 'Delete')),
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
        title: Text(_t('Stockage', 'Storage')),
        scrolledUnderElevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Usage overview ─────────────────────────────────────────
                _SectionHeader(_t('Utilisation', 'Usage'), text),
                const SizedBox(height: 12),
                _UsageCard(stats: _stats!, scheme: scheme, text: text, isEn: _isEn),

                const SizedBox(height: 24),

                // ── Storage limit ──────────────────────────────────────────
                _SectionHeader(_t('Limite de stockage', 'Storage limit'), text),
                const SizedBox(height: 4),
                Text(
                  _t(
                    'Quand la limite est atteinte, les images les moins récentes sont supprimées automatiquement.',
                    'When the limit is reached, least-recently-used images are deleted automatically.',
                  ),
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                _LimitPicker(
                  current:  StorageManager.maxBytes,
                  limits:   _limits,
                  onSelect: _setLimit,
                  scheme:   scheme,
                  text:     text,
                ),

                const SizedBox(height: 24),

                // ── Offline mode ───────────────────────────────────────────
                _SectionHeader(_t('Mode hors ligne', 'Offline mode'), text),
                const SizedBox(height: 8),
                _OfflineModeCard(scheme: scheme, text: text, isEn: _isEn),

                const SizedBox(height: 24),

                // ── Clear categories ───────────────────────────────────────
                _SectionHeader(_t('Nettoyer', 'Clear'), text),
                const SizedBox(height: 8),

                if (_clearing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _ClearTile(
                    icon:     Icons.image_outlined,
                    color:    scheme.primary,
                    title:    _t('Images', 'Images'),
                    subtitle: _t(
                      'Artwork artistes, albums, titres',
                      'Artist, album, track artwork',
                    ),
                    size:     _stats!.imageBytes,
                    onTap:    _clearImages,
                    scheme:   scheme,
                    text:     text,
                    isEn:     _isEn,
                  ),
                  const SizedBox(height: 8),
                  _ClearTile(
                    icon:     Icons.api_outlined,
                    color:    scheme.secondary,
                    title:    _t('Données API', 'API data'),
                    subtitle: _t(
                      'Top artistes, albums, écoutes récentes…',
                      'Top artists, albums, recent tracks…',
                    ),
                    size:     _stats!.apiBytes,
                    onTap:    _clearApiCache,
                    scheme:   scheme,
                    text:     text,
                    isEn:     _isEn,
                  ),
                  const SizedBox(height: 8),
                  _ClearTile(
                    icon:     Icons.history_rounded,
                    color:    scheme.tertiary,
                    title:    _t('Historique scrobbles', 'Scrobble history'),
                    subtitle: _t(
                      'Toutes les écoutes téléchargées',
                      'All downloaded scrobble records',
                    ),
                    size:     _stats!.scrobbleBytes,
                    onTap:    _clearScrobbles,
                    scheme:   scheme,
                    text:     text,
                    isEn:     _isEn,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: _clearAll,
                    icon:  const Icon(Icons.delete_sweep_rounded),
                    label: Text(_t('Tout vider', 'Clear all')),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: scheme.errorContainer,
                      foregroundColor: scheme.onErrorContainer,
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final TextTheme text;
  const _SectionHeader(this.label, this.text);

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: text.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      );
}

// ── Usage card ────────────────────────────────────────────────────────────────

class _UsageCard extends StatelessWidget {
  final StorageStats stats;
  final ColorScheme  scheme;
  final TextTheme    text;
  final bool         isEn;

  const _UsageCard({
    required this.stats,
    required this.scheme,
    required this.text,
    required this.isEn,
  });

  @override
  Widget build(BuildContext context) {
    final total     = stats.totalBytes;
    final max       = stats.maxBytes;
    final unlimited = max <= 0;
    final fraction  = stats.usedFraction;

    final totalStr = StorageManager.formatBytes(total);
    final maxStr   = unlimited
        ? (isEn ? 'Unlimited' : 'Illimité')
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
            isEn ? 'Total used' : 'Espace utilisé',
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
          label:   isEn ? 'Images' : 'Images',
          bytes:   stats.imageBytes,
          total:   total,
          color:   scheme.primary,
          scheme:  scheme,
          text:    text,
        ),
        const SizedBox(height: 6),
        _Bar(
          label:  isEn ? 'API data' : 'Données API',
          bytes:  stats.apiBytes,
          total:  total,
          color:  scheme.secondary,
          scheme: scheme,
          text:   text,
        ),
        const SizedBox(height: 6),
        _Bar(
          label:  isEn ? 'Scrobbles' : 'Historique',
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

// ── Limit picker ──────────────────────────────────────────────────────────────

class _LimitPicker extends StatelessWidget {
  final int    current;
  final List<({String label, int bytes})> limits;
  final void Function(int) onSelect;
  final ColorScheme scheme;
  final TextTheme   text;

  const _LimitPicker({
    required this.current,
    required this.limits,
    required this.onSelect,
    required this.scheme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: limits.map((p) {
        final selected = p.bytes == current;
        return ChoiceChip(
          label:         Text(p.label),
          selected:      selected,
          onSelected:    (_) => onSelect(p.bytes),
          selectedColor: scheme.primaryContainer,
          labelStyle:    text.bodyMedium?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            color:      selected ? scheme.onPrimaryContainer : null,
          ),
        );
      }).toList(),
    );
  }
}

// ── Offline mode toggle ───────────────────────────────────────────────────────

class _OfflineModeCard extends StatefulWidget {
  final ColorScheme scheme;
  final TextTheme   text;
  final bool        isEn;

  const _OfflineModeCard({
    required this.scheme,
    required this.text,
    required this.isEn,
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
      if (mounted) setState(() {
        _keepStale = p.getBool('ls_cache_serve_stale') ?? true;
      });
    });
  }

  Future<void> _toggle(bool v) async {
    setState(() => _keepStale = v);
    DataCache.offlineMode = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('ls_cache_serve_stale', v);
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color:        widget.scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: widget.scheme.outlineVariant.withValues(alpha: 0.45)),
        ),
        child: SwitchListTile(
          value:       _keepStale,
          onChanged:   _toggle,
          contentPadding: EdgeInsets.zero,
          title: Text(
            widget.isEn ? 'Show cached data when offline' : 'Afficher les données en cache hors ligne',
            style: widget.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            widget.isEn
                ? 'Expired data is still shown if no network is available.'
                : 'Les données expirées restent visibles si le réseau est indisponible.',
            style: widget.text.bodySmall?.copyWith(color: widget.scheme.onSurfaceVariant),
          ),
        ),
      );
}

// ── Clear tile ────────────────────────────────────────────────────────────────

class _ClearTile extends StatelessWidget {
  final IconData    icon;
  final Color       color;
  final String      title;
  final String      subtitle;
  final int         size;
  final VoidCallback onTap;
  final ColorScheme  scheme;
  final TextTheme    text;
  final bool         isEn;

  const _ClearTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.size,
    required this.onTap,
    required this.scheme,
    required this.text,
    required this.isEn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${StorageManager.formatBytes(size)} · $subtitle',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        trailing: TextButton(
          onPressed: onTap,
          child: Text(isEn ? 'Clear' : 'Vider',
              style: TextStyle(color: scheme.error)),
        ),
        contentPadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}