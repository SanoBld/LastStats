// lib/screens/settings/dashboard_settings_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/l10n.dart';
import '../../app_state.dart';
import 'settings_helpers.dart';

class DashboardSettingsPage extends StatefulWidget {
  const DashboardSettingsPage({super.key});

  @override
  State<DashboardSettingsPage> createState() => _DashboardSettingsPageState();
}

class _DashboardSettingsPageState extends State<DashboardSettingsPage> {
  String _headerSource          = 'nowplaying';
  String _headerAnimation       = 'fade';
  String _headerPeriod          = 'overall';
  double _headerBlur            = 0.0;
  String _headerCustomUrl       = '';
  // ── Fallback "musique en cours" ──────────────────────────────────────
  // 'none' | 'top_track' | 'top_album' | 'top_artist' | 'custom_url'
  String _fallbackType          = 'none';
  String _fallbackPeriod        = 'overall';   // '7day' | '1month' | 'overall'
  String _fallbackCustomUrl     = '';
  // (conservé pour compatibilité avec l'ancien booléen)
  bool   _headerFallbackEnabled = false;
  String _headerFallbackUrl     = '';
  // ── Sections visibles ────────────────────────────────────────────────
  bool   _showNowPlay           = true;
  bool   _showStats             = true;
  bool   _showArtists           = true;
  bool   _showTracks            = true;
  bool   _showAlbums            = true;
  bool   _showRecent            = true;
  bool   _showFriends           = true;
  bool   _headerMusicAnim       = false; // equalizer animation when music is playing
  List<String> _statCards       = List.from(kDefaultStatCards);

  final _customUrlCtrl         = TextEditingController();
  final _fallbackCustomUrlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    localeNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_rebuild);
    _customUrlCtrl.dispose();
    _fallbackCustomUrlCtrl.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _headerSource          = p.getString('ls_header_source')           ?? 'nowplaying';
      _headerAnimation       = p.getString('ls_header_animation')        ?? 'fade';
      _headerPeriod          = p.getString('ls_header_period')           ?? 'overall';
      _headerBlur            = p.getDouble('ls_header_blur')             ?? 0.0;
      _headerCustomUrl       = p.getString('ls_header_custom_url')       ?? '';
      _fallbackType          = p.getString('ls_header_fallback_type')    ?? 'none';
      _fallbackPeriod        = p.getString('ls_header_fallback_period')  ?? 'overall';
      _fallbackCustomUrl     = p.getString('ls_header_fallback_url')     ?? '';
      _headerFallbackEnabled = p.getBool('ls_header_fallback_enabled')   ?? false;
      _headerFallbackUrl     = p.getString('ls_header_fallback_url')     ?? '';
      _showNowPlay           = p.getBool('ls_show_nowplay')              ?? true;
      _showStats             = p.getBool('ls_show_stats')                ?? true;
      _showArtists           = p.getBool('ls_show_artists')              ?? true;
      _showAlbums            = p.getBool('ls_show_albums')               ?? true;
      _showTracks            = p.getBool('ls_show_tracks')               ?? true;
      _showRecent            = p.getBool('ls_show_recent')               ?? true;
      _showFriends           = p.getBool('ls_show_friends')              ?? true;
      _headerMusicAnim       = p.getBool('ls_header_music_anim')         ?? false;
      final raw = p.getStringList('ls_stat_cards');
      _statCards = raw != null && raw.isNotEmpty ? raw : List.from(kDefaultStatCards);
    });
    _customUrlCtrl.text         = _headerCustomUrl;
    _fallbackCustomUrlCtrl.text = _fallbackCustomUrl;
  }

  Future<void> _set<T>(String key, T v) async {
    final p = await SharedPreferences.getInstance();
    if (v is bool)   await p.setBool(key, v);
    if (v is String) await p.setString(key, v);
    if (v is double) await p.setDouble(key, v);
  }

  Future<void> _saveList(String key, List<String> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(key, list);
  }

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final text    = Theme.of(context).textTheme;
    final sources = buildHeaderSources();
    final anims   = buildHeaderAnimations();
    final periods = buildHeaderPeriods();

    return Scaffold(
      appBar: AppBar(
        title: Text(L.settingsDashboardSection),
        centerTitle: false,
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        // ── Image d'en-tête ───────────────────────────────────────────────
        SettingsSection(label: L.settingsHeaderImage, children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 14), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Source
              Row(children: [
                Icon(Icons.wallpaper_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(L.settingsHeaderSource,
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              Text(L.settingsHeaderImageSub,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: sources.map((opt) {
                final (key, label, icon) = opt;
                final sel = _headerSource == key;
                return FilterChip(
                  avatar: Icon(icon, size: 16), label: Text(label),
                  selected: sel, showCheckmark: false,
                  onSelected: (_) async {
                    await _set('ls_header_source', key);
                    setState(() => _headerSource = key);
                  },
                );
              }).toList()),

              // ── URL personnalisée (source = custom) ───────────────────
              if (_headerSource == 'custom') ...[
                const SizedBox(height: 16),
                Divider(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Row(children: [
                  Icon(Icons.link_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(L.settingsHeaderCustomUrl,
                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 8),
                TextField(
                  controller: _customUrlCtrl, autocorrect: false,
                  keyboardType: TextInputType.url, textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: L.settingsHeaderCustomUrlHint,
                    prefixIcon: const Icon(Icons.image_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      tooltip: L.settingsHeaderApply,
                      onPressed: () async {
                        final url = _customUrlCtrl.text.trim();
                        await _set('ls_header_custom_url', url);
                        setState(() => _headerCustomUrl = url);
                      },
                    ),
                  ),
                  onSubmitted: (url) async {
                    await _set('ls_header_custom_url', url.trim());
                    setState(() => _headerCustomUrl = url.trim());
                  },
                ),
                const SizedBox(height: 6),
                Text(L.settingsHeaderCustomUrlSub,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],

              // ── Période (source = top_*) ───────────────────────────────
              if (['top_track', 'top_album', 'top_artist'].contains(_headerSource)) ...[
                const SizedBox(height: 16),
                Divider(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Row(children: [
                  Icon(Icons.date_range_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(L.settingsHeaderPeriod,
                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: periods.map((opt) {
                  final (key, label) = opt;
                  return FilterChip(
                    label: Text(label), selected: _headerPeriod == key, showCheckmark: false,
                    onSelected: (_) async {
                      await _set('ls_header_period', key);
                      setState(() => _headerPeriod = key);
                    },
                  );
                }).toList()),
              ],

              // ── Fallback "Aucune musique en cours" (source = nowplaying) ─
              if (_headerSource == 'nowplaying') ...[
                const SizedBox(height: 16),
                Divider(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 14),
                Row(children: [
                  Icon(Icons.music_off_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      L.dashFallbackWhenNoMusic,
                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      L.dashFallbackChooseDisplay,
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ])),
                ]),
                const SizedBox(height: 12),

                // Choix du type de fallback
                _FallbackTypeSelector(
                  value: _fallbackType,
                  scheme: scheme,
                  text: text,
                  onChanged: (val) async {
                    await _set('ls_header_fallback_type', val);
                    // Rétrocompatibilité : met à jour l'ancien booléen
                    await _set('ls_header_fallback_enabled', val != 'none');
                    setState(() => _fallbackType = val);
                  },
                ),

                // Période (si fallback = top_track / top_album / top_artist)
                if (['top_track', 'top_album', 'top_artist'].contains(_fallbackType)) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    Icon(Icons.date_range_rounded, size: 16, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      L.dashFallbackPeriodLabel,
                      style: text.labelMedium?.copyWith(
                          color: scheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _FallbackPeriodChip(
                      label: L.fallbackPeriod1Week,
                      value: '7day',
                      selected: _fallbackPeriod,
                      onTap: (v) async {
                        await _set('ls_header_fallback_period', v);
                        setState(() => _fallbackPeriod = v);
                      },
                    ),
                    _FallbackPeriodChip(
                      label: L.fallbackPeriod1Month,
                      value: '1month',
                      selected: _fallbackPeriod,
                      onTap: (v) async {
                        await _set('ls_header_fallback_period', v);
                        setState(() => _fallbackPeriod = v);
                      },
                    ),
                    _FallbackPeriodChip(
                      label: L.fallbackPeriodAllTime,
                      value: 'overall',
                      selected: _fallbackPeriod,
                      onTap: (v) async {
                        await _set('ls_header_fallback_period', v);
                        setState(() => _fallbackPeriod = v);
                      },
                    ),
                  ]),
                ],

                // URL personnalisée de fallback
                if (_fallbackType == 'custom_url') ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _fallbackCustomUrlCtrl, autocorrect: false,
                    keyboardType: TextInputType.url, textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: L.settingsHeaderFallbackUrlLabel,
                      hintText: L.settingsHeaderCustomUrlHint,
                      prefixIcon: const Icon(Icons.image_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        tooltip: L.settingsHeaderApply,
                        onPressed: () async {
                          final url = _fallbackCustomUrlCtrl.text.trim();
                          await _set('ls_header_fallback_url', url);
                          setState(() => _fallbackCustomUrl = url);
                        },
                      ),
                    ),
                    onSubmitted: (url) async {
                      await _set('ls_header_fallback_url', url.trim());
                      setState(() => _fallbackCustomUrl = url.trim());
                    },
                  ),
                ],

                // Aperçu du fallback actif
                if (_fallbackType != 'none') ...[
                  const SizedBox(height: 12),
                  _FallbackSummary(type: _fallbackType, period: _fallbackPeriod),
                ],
              ],
            ],
          )),
        ]),

        const SizedBox(height: 16),

        // ── Animation & Flou ──────────────────────────────────────────────
        SettingsSection(label: L.dashAnimationBlurSection, children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.animation_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(L.settingsHeaderAnimation,
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              Text(L.settingsHeaderAnimationSub,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: anims.map((opt) {
                final (key, label, icon) = opt;
                return FilterChip(
                  avatar: Icon(icon, size: 16), label: Text(label),
                  selected: _headerAnimation == key, showCheckmark: false,
                  onSelected: (_) async {
                    await _set('ls_header_animation', key);
                    setState(() => _headerAnimation = key);
                  },
                );
              }).toList()),

              const SizedBox(height: 16),
              Divider(color: scheme.outlineVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 12),

              Row(children: [
                Icon(Icons.blur_on_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(L.settingsHeaderBlur,
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scheme.outlineVariant)),
                  child: Text(
                    _headerBlur < 1 ? L.settingsHeaderBlurNone : '${_headerBlur.round()}',
                    style: text.labelMedium?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Slider(
                value: _headerBlur, min: 0, max: 20, divisions: 20,
                label: _headerBlur < 1 ? L.settingsHeaderBlurNone : '${_headerBlur.round()}',
                onChanged: (v) => setState(() => _headerBlur = v),
                onChangeEnd: (v) async => await _set('ls_header_blur', v),
              ),
              const SizedBox(height: 8),

              // ── Music playback animation ──────────────────────────────
              const SizedBox(height: 16),
              Divider(color: scheme.outlineVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(Icons.blur_on_rounded, color: scheme.primary),
                title: Text(
                  L.dashMusicAnimationTitle,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  L.dashMusicAnimationSub,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                value: _headerMusicAnim,
                onChanged: (v) async {
                  final p = await SharedPreferences.getInstance();
                  await p.setBool('ls_header_music_anim', v);
                  setState(() => _headerMusicAnim = v);
                },
              ),
              // Info: blur is forced to 18 when the animation is active,
              // overriding the manual blur slider value.
              if (_headerMusicAnim) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      L.dashMusicAnimationInfo,
                      style: text.bodySmall?.copyWith(
                          color: scheme.onPrimaryContainer),
                    )),
                  ]),
                ),
              ],
            ],
          )),
        ]),

        const SizedBox(height: 16),

        // ── Sections visibles ─────────────────────────────────────────────
        SettingsSection(label: L.settingsVisibleSections, children: [
          SwitchListTile(
            secondary: const Icon(Icons.play_circle_outline_rounded),
            title: Text(L.settingsNowPlayingSection), value: _showNowPlay,
            onChanged: (v) async { await _set('ls_show_nowplay', v); setState(() => _showNowPlay = v); }),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: const Icon(Icons.bar_chart_rounded),
            title: Text(L.settingsStatsSection), value: _showStats,
            onChanged: (v) async { await _set('ls_show_stats', v); setState(() => _showStats = v); }),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: const Icon(Icons.mic_rounded),
            title: Text(L.settingsTopArtistsSection), value: _showArtists,
            onChanged: (v) async { await _set('ls_show_artists', v); setState(() => _showArtists = v); }),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: const Icon(Icons.album_rounded),
            title: Text(L.settingsTopAlbumsSection), value: _showAlbums,
            onChanged: (v) async { await _set('ls_show_albums', v); setState(() => _showAlbums = v); }),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: const Icon(Icons.music_note_rounded),
            title: Text(L.settingsTopTracksSection), value: _showTracks,
            onChanged: (v) async { await _set('ls_show_tracks', v); setState(() => _showTracks = v); }),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: const Icon(Icons.history_rounded),
            title: Text(L.dashRecentPlaysLabel), value: _showRecent,
            onChanged: (v) async { await _set('ls_show_recent', v); setState(() => _showRecent = v); }),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: const Icon(Icons.people_rounded),
            title: Text(L.settingsFriendsSection),
            subtitle: Text(L.settingsFriendsSectionSub),
            value: _showFriends,
            onChanged: (v) async { await _set('ls_show_friends', v); setState(() => _showFriends = v); }),
        ]),

        const SizedBox(height: 16),

        // ── Cartes de statistiques ────────────────────────────────────────
        SettingsSection(
          label: L.dashStatCardsSectionLabel,
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.grid_view_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(L.dashStatCardsHeading,
                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 4),
                Text(L.dashStatCardsSub,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            )),
            ...kAllStatCards.map((card) {
              final (id, emoji, _, _, _, _, _) = card;
              final label   = statCardLabel(id);
              final enabled = _statCards.contains(id);
              return CheckboxListTile(
                secondary: Text(emoji, style: const TextStyle(fontSize: 20)),
                title: Text(label),
                value: enabled,
                controlAffinity: ListTileControlAffinity.trailing,
                dense: true,
                onChanged: (v) async {
                  final updated = List<String>.from(_statCards);
                  if (v == true) { if (!updated.contains(id)) updated.add(id); }
                  else { updated.remove(id); }
                  await _saveList('ls_stat_cards', updated);
                  setState(() => _statCards = updated);
                },
              );
            }),
            Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 14), child: FilledButton.tonalIcon(
              icon: const Icon(Icons.swap_vert_rounded, size: 18),
              label: Text(L.reorderCardsTitle),
              onPressed: () async {
                final result = await showModalBottomSheet<List<String>>(
                  context: context, isScrollControlled: true,
                  backgroundColor: Colors.transparent, useSafeArea: true,
                  builder: (_) => CardReorderSheet(cards: List.from(_statCards)),
                );
                if (result != null && mounted) {
                  await _saveList('ls_stat_cards', result);
                  setState(() => _statCards = result);
                }
              },
            )),
          ],
        ),

        const SizedBox(height: 20),
        const RestartBanner(),
        const SizedBox(height: 20),
      ]),
    );
  }
}

// ── Widget sélecteur de type de fallback ──────────────────────────────────────

class _FallbackTypeSelector extends StatelessWidget {
  final String value;
  final ColorScheme scheme;
  final TextTheme text;
  final void Function(String) onChanged;

  const _FallbackTypeSelector({
    required this.value,
    required this.scheme,
    required this.text,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      ('none',        Icons.hide_image_outlined,   L.fallbackTypeNothing),
      ('top_track',   Icons.music_note_rounded,    L.fallbackTypeTopTrack),
      ('top_album',   Icons.album_rounded,         L.fallbackTypeTopAlbum),
      ('top_artist',  Icons.mic_rounded,           L.fallbackTypeTopArtist),
      ('custom_url',  Icons.image_outlined,        L.fallbackTypeCustomImage),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options.map((opt) {
        final (key, icon, label) = opt;
        final sel = value == key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onChanged(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: sel
                    ? scheme.primaryContainer.withValues(alpha: 0.7)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel
                      ? scheme.primary.withValues(alpha: 0.55)
                      : scheme.outlineVariant.withValues(alpha: 0.4),
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Icon(icon,
                    size: 18,
                    color: sel ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Text(label, style: text.bodyMedium?.copyWith(
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? scheme.onPrimaryContainer : scheme.onSurface,
                )),
                const Spacer(),
                if (sel)
                  Icon(Icons.check_circle_rounded, size: 18, color: scheme.primary)
                else
                  Icon(Icons.radio_button_unchecked_rounded,
                      size: 18, color: scheme.outlineVariant),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Chip de période pour le fallback ─────────────────────────────────────────

class _FallbackPeriodChip extends StatelessWidget {
  final String label, value, selected;
  final void Function(String) onTap;
  const _FallbackPeriodChip({
    required this.label, required this.value,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sel = value == selected;
    return FilterChip(
      label: Text(label),
      selected: sel,
      showCheckmark: false,
      onSelected: (_) => onTap(value),
    );
  }
}

// ── Résumé du fallback actif ──────────────────────────────────────────────────

class _FallbackSummary extends StatelessWidget {
  final String type, period;
  const _FallbackSummary({required this.type, required this.period});

  String _typeLabel() {
    switch (type) {
      case 'top_track':  return L.fallbackTypeTopTrack;
      case 'top_album':  return L.fallbackTypeTopAlbum;
      case 'top_artist': return L.fallbackTypeTopArtist;
      case 'custom_url': return L.fallbackTypeCustomImage;
      default: return '';
    }
  }

  String _periodLabel() {
    switch (period) {
      case '7day':   return L.fallbackPeriod1Week;
      case '1month': return L.fallbackPeriod1Month;
      default:       return L.fallbackPeriodAllTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    final showPeriod = ['top_track', 'top_album', 'top_artist'].contains(type);
    final summary = showPeriod
        ? L.fallbackWillShow('${_typeLabel()} · ${_periodLabel()}')
        : (type == 'custom_url' ? L.fallbackWillShowCustomUrl : '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(Icons.info_outline_rounded, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(summary,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
      ]),
    );
  }
}