// ignore_for_file: unused_import
part of 'home_screen.dart';

class _SettingsPage extends StatefulWidget {
  final String username; const _SettingsPage({required this.username});

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  String _theme = 'system', _accent = 'purple';
  bool   _useDynamicColor = false, _useNowPlayingColor = false;
  int    _startupTab = 0;
  String _headerSource = 'nowplaying';
  double _headerBlur = 0.0;
  String _headerAnimation = 'fade';
  String _headerCustomUrl = '';
  String _headerFallbackUrl = '';
  bool   _headerFallbackEnabled = false;
  String _headerPeriod = 'overall';
  bool   _showNowPlay = true, _showStats = true, _showArtists = true, _showTracks = true;
  bool   _showFriends = true;
  bool   _autoUpdate = true;
  String _locale = 'fr';
  UpdateInfo? _updateInfo; bool _checkingUpdate = false; String? _updateError;

  final _customUrlCtrl   = TextEditingController();
  final _fallbackUrlCtrl = TextEditingController();

  bool get _isCustomAccent =>
      _accent.startsWith('#') ||
      !_kAccentOptions.any((o) => o.$2 == _accent);

  @override
  void dispose() {
    _customUrlCtrl.dispose();
    _fallbackUrlCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() { super.initState(); _loadPrefs().then((_) => _maybeCheckUpdate()); }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _theme                = p.getString('ls_theme')                    ?? 'system';
      _accent               = p.getString('ls_accent')                   ?? 'purple';
      _useDynamicColor      = p.getBool('ls_use_dynamic_color')          ?? false;
      _useNowPlayingColor   = p.getBool('ls_use_nowplaying_color')       ?? false;
      _startupTab           = p.getInt('ls_startup_tab')                 ?? 0;
      _headerSource         = p.getString('ls_header_source')            ?? 'nowplaying';
      _headerBlur           = p.getDouble('ls_header_blur')              ?? 0.0;
      _headerAnimation      = p.getString('ls_header_animation')         ?? 'fade';
      _headerCustomUrl      = p.getString('ls_header_custom_url')        ?? '';
      _headerFallbackUrl    = p.getString('ls_header_fallback_url')      ?? '';
      _headerFallbackEnabled = p.getBool('ls_header_fallback_enabled')   ?? false;
      _headerPeriod         = p.getString('ls_header_period')            ?? 'overall';
      _showNowPlay          = p.getBool('ls_show_nowplay')               ?? true;
      _showStats            = p.getBool('ls_show_stats')                 ?? true;
      _showArtists          = p.getBool('ls_show_artists')               ?? true;
      _showTracks           = p.getBool('ls_show_tracks')                ?? true;
      _showFriends          = p.getBool('ls_show_friends')               ?? true;
      _autoUpdate           = p.getBool('ls_auto_update_check')          ?? true;
      _locale               = p.getString('ls_locale')                   ?? 'fr';
    });
    _customUrlCtrl.text   = _headerCustomUrl;
    _fallbackUrlCtrl.text = _headerFallbackUrl;
  }

  Future<void> _maybeCheckUpdate() async {
    if (!_autoUpdate) return;
    final p = await SharedPreferences.getInstance();
    if (DateTime.now().millisecondsSinceEpoch - (p.getInt('ls_last_update_check') ?? 0) <
        const Duration(days: 1).inMilliseconds) { return; }
    await _checkUpdate(auto: true);
  }

  Future<void> _checkUpdate({bool auto = false}) async {
    if (!mounted) return;
    setState(() { _checkingUpdate = true; _updateError = null; });
    try {
      final info = await UpdateService.checkForUpdate();
      if (!mounted) return;
      final p = await SharedPreferences.getInstance();
      await p.setInt('ls_last_update_check', DateTime.now().millisecondsSinceEpoch);
      setState(() { _updateInfo = info; _checkingUpdate = false; });
    } catch (_) {
      if (mounted) setState(() { _updateError = L.settingsCheckFailed; _checkingUpdate = false; });
    }
  }

  Future<void> _set<T>(String key, T v) async {
    final p = await SharedPreferences.getInstance();
    if (v is bool)   { await p.setBool(key, v); }
    if (v is String) { await p.setString(key, v); }
    if (v is int)    { await p.setInt(key, v); }
  }

  // ── Language ──────────────────────────────────────────────────────────────

  Future<void> _setLocale(String code) async {
    await _set('ls_locale', code);
    setState(() => _locale = code);
    localeNotifier.value = code;
  }

  // ── Backup / Restore ──────────────────────────────────────────────────────

  static const _kBackupKeys = [
    'ls_username', 'ls_apikey',
    'ls_theme', 'ls_accent', 'ls_use_dynamic_color', 'ls_use_nowplaying_color',
    'ls_header_source', 'ls_header_period', 'ls_header_animation',
    'ls_header_blur', 'ls_header_custom_url',
    'ls_header_fallback_enabled', 'ls_header_fallback_url',
    'ls_show_nowplay', 'ls_show_stats', 'ls_show_artists', 'ls_show_tracks', 'ls_show_friends',
    'ls_startup_tab', 'ls_auto_update_check',
    'ls_fav_friends', 'ls_fav_profiles', 'ls_locale',
  ];

  Future<void> _exportBackup() async {
    final p   = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    for (final key in _kBackupKeys) {
      final v = p.get(key);
      if (v != null) { map[key] = v; }
    }
    final now     = DateTime.now();
    final payload = jsonEncode({
      'app':         'LastStats',
      'version':     '1',
      'exported_at': now.toIso8601String(),
      'prefs':       map,
    });
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final defaultName = 'laststats_backup_$dateStr.json';
    if (!mounted) return;
    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      useSafeArea: true, backgroundColor: Colors.transparent,
      builder: (ctx) => _ExportSheet(payload: payload, defaultName: defaultName),
    );
  }

  Future<void> _showImportDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) {
        String? err;
        return StatefulBuilder(builder: (ctx, setDlg) {
          return AlertDialog(
            title: Text(L.importTitle),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L.importHintLabel, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl, maxLines: 5, autofocus: true,
                  decoration: InputDecoration(
                    hintText: '{"app":"LastStats",...}',
                    border: const OutlineInputBorder(),
                    errorText: err,
                  ),
                  onChanged: (_) { if (err != null) { setDlg(() => err = null); } },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(L.commonCancel)),
              FilledButton(
                onPressed: () async {
                  final raw = ctrl.text.trim();
                  if (raw.isEmpty) { setDlg(() => err = L.importEmpty); return; }
                  Map<String, dynamic> parsed;
                  try { parsed = jsonDecode(raw) as Map<String, dynamic>; }
                  catch (_) { setDlg(() => err = L.importInvalidJson); return; }
                  if (parsed['app'] != 'LastStats') { setDlg(() => err = L.importUnknownFile); return; }
                  final prefs = parsed['prefs'];
                  if (prefs is! Map) { setDlg(() => err = L.importInvalidFormat); return; }
                  if (ctx.mounted) { Navigator.pop(ctx); }
                  await _applyBackup(Map<String, dynamic>.from(prefs));
                },
                child: Text(L.importRestore),
              ),
            ],
          );
        });
      },
    );
    ctrl.dispose();
  }

  Future<void> _applyBackup(Map<String, dynamic> prefs) async {
    final p = await SharedPreferences.getInstance();
    for (final entry in prefs.entries) {
      final k = entry.key; final v = entry.value;
      if (!k.startsWith('ls_')) { continue; }
      if (v is bool)   { await p.setBool(k, v); }
      else if (v is int)    { await p.setInt(k, v); }
      else if (v is double) { await p.setDouble(k, v); }
      else if (v is String) { await p.setString(k, v); }
      else if (v is List)   { await p.setStringList(k, List<String>.from(v)); }
    }
    themeModeNotifier.value          = themeFromString(p.getString('ls_theme'));
    accentNotifier.value             = accentFromString(p.getString('ls_accent'));
    useDynamicColorNotifier.value    = p.getBool('ls_use_dynamic_color')    ?? false;
    useNowPlayingColorNotifier.value = p.getBool('ls_use_nowplaying_color') ?? false;
    localeNotifier.value             = p.getString('ls_locale')             ?? 'fr';
    await _loadPrefs();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(L.importSuccess), behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _setTheme(String v) async {
    await _set('ls_theme', v); setState(() => _theme = v);
    themeModeNotifier.value = themeFromString(v);
  }

  Future<void> _setAccentPreset(String key, Color color) async {
    await _set('ls_accent', key); setState(() => _accent = key);
    if (!_useDynamicColor && !_useNowPlayingColor) accentNotifier.value = color;
  }

  Future<void> _pickCustomColor() async {
    if (_useDynamicColor || _useNowPlayingColor) return;
    final current = accentNotifier.value;
    final result = await showDialog<Color>(
      context: context,
      builder: (_) => _ColorPickerDialog(initialColor: current),
    );
    if (result != null && mounted) {
      final hex = colorToHex(result);
      await _set('ls_accent', hex);
      setState(() => _accent = hex);
      accentNotifier.value = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final currentAccent = accentNotifier.value;

    final headerSources   = _localizedHeaderSources();
    final headerAnims     = _localizedHeaderAnimations();
    final headerPeriods   = _localizedHeaderPeriods();
    final startupLabels   = _localizedStartupLabels();

    return SafeArea(
      child: ListView(padding: const EdgeInsets.all(20), children: [
        Text(L.settingsTitle, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),

        // ── Update banner ────────────────────────────────────────────────
        if (_updateInfo != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4))),
            child: Row(children: [
              Icon(Icons.system_update_rounded, color: scheme.onTertiaryContainer, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(L.settingsUpdateBanner(_updateInfo!.version),
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700,
                        color: scheme.onTertiaryContainer)),
                if (_updateInfo!.notes.isNotEmpty)
                  Text(_updateInfo!.notes.length > 100
                      ? '${_updateInfo!.notes.substring(0, 100)}…' : _updateInfo!.notes,
                      style: text.bodySmall?.copyWith(color: scheme.onTertiaryContainer.withValues(alpha: 0.8))),
              ])),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () async {
                  final url = Uri.parse(_updateInfo!.hasApk ? _updateInfo!.apkUrl! : _updateInfo!.releaseUrl);
                  if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                },
                style: FilledButton.styleFrom(
                    backgroundColor: scheme.tertiary, foregroundColor: scheme.onTertiary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: text.labelMedium),
                child: Text(_updateInfo!.hasApk ? L.settingsDownload : L.settingsViewRelease),
              ),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        // ── Language ────────────────────────────────────────────────────
        _SettingsSection(label: L.settingsLanguage, children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 14), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.translate_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(L.settingsLanguage, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'fr', label: Text('Français'), icon: Text('🇫🇷')),
                  ButtonSegment(value: 'en', label: Text('English'),  icon: Text('🇬🇧')),
                ],
                selected: {_locale},
                onSelectionChanged: (s) => _setLocale(s.first),
                style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ],
          )),
        ]),

        const SizedBox(height: 16),

        // ── Appearance ───────────────────────────────────────────────────
        _SettingsSection(label: L.settingsAppearance, children: [

          // Theme
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 10), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.contrast_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(L.settingsTheme, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'system', icon: const Icon(Icons.brightness_auto_rounded), label: Text(L.settingsThemeAuto)),
                  ButtonSegment(value: 'light',  icon: const Icon(Icons.light_mode_rounded),       label: Text(L.settingsThemeLight)),
                  ButtonSegment(value: 'dark',   icon: const Icon(Icons.dark_mode_rounded),        label: Text(L.settingsThemeDark)),
                ],
                selected: {_theme},
                onSelectionChanged: (s) => _setTheme(s.first),
                style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ],
          )),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Accent color
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 14), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.palette_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(L.settingsAccentColor, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (_useDynamicColor || _useNowPlayingColor) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scheme.outlineVariant)),
                    child: Text(L.settingsAccentAuto, style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant))),
                ],
              ]),
              const SizedBox(height: 12),
              Opacity(
                opacity: (_useDynamicColor || _useNowPlayingColor) ? 0.35 : 1.0,
                child: Wrap(spacing: 10, runSpacing: 10, children: [
                  ..._kAccentOptions.map((opt) {
                    final (color, key, label) = opt;
                    final sel = _accent == key;
                    return GestureDetector(
                      onTap: (_useDynamicColor || _useNowPlayingColor) ? null : () => _setAccentPreset(key, color),
                      child: Tooltip(message: label, child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle,
                          border: sel ? Border.all(color: scheme.onSurface, width: 3)
                              : Border.all(color: scheme.outlineVariant, width: 1.5),
                          boxShadow: sel ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)] : [],
                        ),
                        child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                      )),
                    );
                  }),
                  GestureDetector(
                    onTap: (_useDynamicColor || _useNowPlayingColor) ? null : _pickCustomColor,
                    child: Tooltip(
                      message: L.colorCustomTooltip,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _isCustomAccent ? null : const SweepGradient(colors: [
                            Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00),
                            Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF), Color(0xFFFF0000),
                          ]),
                          color: _isCustomAccent ? currentAccent : null,
                          border: _isCustomAccent
                              ? Border.all(color: scheme.onSurface, width: 3)
                              : Border.all(color: scheme.outlineVariant, width: 1.5),
                          boxShadow: _isCustomAccent
                              ? [BoxShadow(color: currentAccent.withValues(alpha: 0.5), blurRadius: 8)] : [],
                        ),
                        child: _isCustomAccent
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                            : const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ]),
              ),
              if (_isCustomAccent && !_useDynamicColor && !_useNowPlayingColor) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Container(width: 18, height: 18,
                    decoration: BoxDecoration(color: currentAccent, shape: BoxShape.circle,
                        border: Border.all(color: scheme.outlineVariant))),
                  const SizedBox(width: 8),
                  Text(colorToHex(currentAccent),
                      style: text.bodySmall?.copyWith(fontFamily: 'monospace', color: scheme.onSurfaceVariant)),
                  const SizedBox(width: 8),
                  TextButton(onPressed: _pickCustomColor, child: Text(L.settingsCustomColorEdit)),
                ]),
              ],
            ],
          )),
        ]),

        const SizedBox(height: 16),

        // ── Dynamic color ────────────────────────────────────────────────
        _SettingsSection(label: L.settingsDynamicColor, children: [
          SwitchListTile(
            secondary: Icon(Icons.colorize_rounded, color: scheme.primary),
            title: Text(L.settingsMaterialYou),
            subtitle: Text(L.settingsMaterialYouSub),
            value: _useDynamicColor,
            onChanged: (v) async {
              await _set('ls_use_dynamic_color', v);
              setState(() { _useDynamicColor = v; if (v) _useNowPlayingColor = false; });
              useDynamicColorNotifier.value    = v;
              useNowPlayingColorNotifier.value = false;
              if (!v) accentNotifier.value = accentFromString(_accent);
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: Icon(Icons.album_rounded,
                color: _useDynamicColor ? scheme.onSurfaceVariant : scheme.primary),
            title: Text(L.settingsMusicColor),
            subtitle: Text(_useDynamicColor ? L.settingsMusicColorLocked : L.settingsMusicColorSub),
            value: _useNowPlayingColor,
            onChanged: _useDynamicColor ? null : (v) async {
              await _set('ls_use_nowplaying_color', v);
              setState(() => _useNowPlayingColor = v);
              useNowPlayingColorNotifier.value = v;
              if (!v) accentNotifier.value = accentFromString(_accent);
            },
          ),
          Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(L.settingsMusicColorNote,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
        ]),

        const SizedBox(height: 16),

        // ── Startup page ──────────────────────────────────────────────────
        _SettingsSection(label: L.settingsStartupPage, children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 14), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.rocket_launch_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(L.settingsStartupTab, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8,
                children: startupLabels.asMap().entries.map((e) => FilterChip(
                  avatar: Icon(e.value.$1, size: 16), label: Text(e.value.$2),
                  selected: _startupTab == e.key, showCheckmark: false,
                  onSelected: (_) async { await _set('ls_startup_tab', e.key); setState(() => _startupTab = e.key); },
                )).toList()),
            ],
          )),
        ]),

        const SizedBox(height: 16),

        // ── Dashboard ─────────────────────────────────────────────────────
        _SettingsSection(label: L.settingsDashboardSection, children: [

          // Header image
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.wallpaper_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(L.settingsHeaderImage, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              Text(L.settingsHeaderImageSub,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 12),

              Text(L.settingsHeaderSource, style: text.labelSmall?.copyWith(
                  color: scheme.primary, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8,
                children: headerSources.map((opt) {
                  final (key, label, icon) = opt;
                  final sel = _headerSource == key;
                  return FilterChip(
                    avatar: Icon(icon, size: 16), label: Text(label),
                    selected: sel, showCheckmark: false,
                    onSelected: (_) async {
                      final p = await SharedPreferences.getInstance();
                      await p.setString('ls_header_source', key);
                      setState(() => _headerSource = key);
                    },
                  );
                }).toList()),

              if (_headerSource == 'custom') ...[
                const SizedBox(height: 14),
                Text(L.settingsHeaderCustomUrl, style: text.labelSmall?.copyWith(
                    color: scheme.primary, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                TextField(
                  controller: _customUrlCtrl, autocorrect: false,
                  keyboardType: TextInputType.url, textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: L.settingsHeaderCustomUrlHint,
                    prefixIcon: const Icon(Icons.link_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      tooltip: L.settingsHeaderApply,
                      onPressed: () async {
                        final url = _customUrlCtrl.text.trim();
                        final p = await SharedPreferences.getInstance();
                        await p.setString('ls_header_custom_url', url);
                        setState(() => _headerCustomUrl = url);
                      },
                    ),
                  ),
                  onSubmitted: (url) async {
                    final u = url.trim();
                    final p = await SharedPreferences.getInstance();
                    await p.setString('ls_header_custom_url', u);
                    setState(() => _headerCustomUrl = u);
                  },
                ),
                const SizedBox(height: 6),
                Text(L.settingsHeaderCustomUrlSub,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],

              if (['top_track', 'top_album', 'top_artist'].contains(_headerSource)) ...[
                const SizedBox(height: 14),
                Text(L.settingsHeaderPeriod, style: text.labelSmall?.copyWith(
                    color: scheme.primary, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8,
                  children: headerPeriods.map((opt) {
                    final (key, label) = opt;
                    return FilterChip(
                      label: Text(label), selected: _headerPeriod == key, showCheckmark: false,
                      onSelected: (_) async {
                        final p = await SharedPreferences.getInstance();
                        await p.setString('ls_header_period', key);
                        setState(() => _headerPeriod = key);
                      },
                    );
                  }).toList()),
              ],

              if (_headerSource == 'nowplaying') ...[
                const SizedBox(height: 14),
                Row(children: [
                  Switch(
                    value: _headerFallbackEnabled,
                    onChanged: (v) async {
                      final p = await SharedPreferences.getInstance();
                      await p.setBool('ls_header_fallback_enabled', v);
                      setState(() => _headerFallbackEnabled = v);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(L.settingsHeaderFallback, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Text(L.settingsHeaderFallbackSub,
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ])),
                ]),
                if (_headerFallbackEnabled) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _fallbackUrlCtrl, autocorrect: false,
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
                          final url = _fallbackUrlCtrl.text.trim();
                          final p = await SharedPreferences.getInstance();
                          await p.setString('ls_header_fallback_url', url);
                          setState(() => _headerFallbackUrl = url);
                        },
                      ),
                    ),
                    onSubmitted: (url) async {
                      final u = url.trim();
                      final p = await SharedPreferences.getInstance();
                      await p.setString('ls_header_fallback_url', u);
                      setState(() => _headerFallbackUrl = u);
                    },
                  ),
                ],
              ],

              const SizedBox(height: 16),
              Divider(color: scheme.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 12),

              Row(children: [
                Icon(Icons.animation_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(L.settingsHeaderAnimation, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              Text(L.settingsHeaderAnimationSub,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8,
                children: headerAnims.map((opt) {
                  final (key, label, icon) = opt;
                  return FilterChip(
                    avatar: Icon(icon, size: 16), label: Text(label),
                    selected: _headerAnimation == key, showCheckmark: false,
                    onSelected: (_) async {
                      final p = await SharedPreferences.getInstance();
                      await p.setString('ls_header_animation', key);
                      setState(() => _headerAnimation = key);
                    },
                  );
                }).toList()),

              const SizedBox(height: 16),

              Row(children: [
                Icon(Icons.blur_on_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(L.settingsHeaderBlur, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8), border: Border.all(color: scheme.outlineVariant)),
                  child: Text(_headerBlur < 1 ? L.settingsHeaderBlurNone : '${_headerBlur.round()}',
                      style: text.labelMedium?.copyWith(fontFamily: 'monospace')),
                ),
              ]),
              const SizedBox(height: 4),
              Slider(
                value: _headerBlur, min: 0, max: 20, divisions: 20,
                label: _headerBlur < 1 ? L.settingsHeaderBlurNone : '${_headerBlur.round()}',
                onChanged: (v) => setState(() => _headerBlur = v),
                onChangeEnd: (v) async {
                  final p = await SharedPreferences.getInstance();
                  await p.setDouble('ls_header_blur', v);
                },
              ),
              const SizedBox(height: 10),
            ],
          )),

          const Divider(height: 1, indent: 16, endIndent: 16),

          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(L.settingsVisibleSections, style: text.bodySmall
                ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700))),
          SwitchListTile(secondary: const Icon(Icons.play_circle_outline_rounded),
            title: Text(L.settingsNowPlayingSection), value: _showNowPlay,
            onChanged: (v) async { await _set('ls_show_nowplay', v); setState(() => _showNowPlay = v); }),
          SwitchListTile(secondary: const Icon(Icons.bar_chart_rounded),
            title: Text(L.settingsStatsSection), value: _showStats,
            onChanged: (v) async { await _set('ls_show_stats', v); setState(() => _showStats = v); }),
          SwitchListTile(secondary: const Icon(Icons.mic_rounded),
            title: Text(L.settingsTopArtistsSection), value: _showArtists,
            onChanged: (v) async { await _set('ls_show_artists', v); setState(() => _showArtists = v); }),
          SwitchListTile(secondary: const Icon(Icons.music_note_rounded),
            title: Text(L.settingsTopTracksSection), value: _showTracks,
            onChanged: (v) async { await _set('ls_show_tracks', v); setState(() => _showTracks = v); }),
          SwitchListTile(secondary: const Icon(Icons.people_rounded),
            title: Text(L.settingsFriendsSection),
            subtitle: Text(L.settingsFriendsSectionSub),
            value: _showFriends,
            onChanged: (v) async { await _set('ls_show_friends', v); setState(() => _showFriends = v); }),
        ]),

        const SizedBox(height: 16),

        // ── Account ───────────────────────────────────────────────────────
        _SettingsSection(label: L.settingsAccount, children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Text(widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '?',
                  style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700))),
            title: Text(widget.username, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(L.settingsConnectedProfile)),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: scheme.error),
            title: Text(L.settingsLogout, style: TextStyle(color: scheme.error)),
            onTap: () async {
              final ok = await showDialog<bool>(context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(L.settingsLogoutTitle),
                  content: Text(L.settingsLogoutContent),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(L.commonCancel)),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(L.settingsLogoutConfirm)),
                  ],
                ));
              if (ok == true && mounted) {
                // Capture navigator before any async gap
                final nav = Navigator.of(context);
                final p = await SharedPreferences.getInstance();
                await p.remove('ls_username');
                await p.remove('ls_apikey');
                // Use the pre-captured navigator — no BuildContext used after await
                nav.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SetupScreen()), (_) => false);
              }
            }),
        ]),

        const SizedBox(height: 16),

        // ── Backup ────────────────────────────────────────────────────────
        _SettingsSection(label: L.settingsBackup, children: [
          ListTile(
            leading: Icon(Icons.upload_rounded, color: scheme.primary),
            title: Text(L.settingsExport),
            subtitle: Text(L.settingsExportSub),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _exportBackup,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(Icons.download_rounded, color: scheme.primary),
            title: Text(L.settingsImport),
            subtitle: Text(L.settingsImportSub),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _showImportDialog,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(child: Text(L.settingsBackupInfo,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant))),
            ]),
          ),
        ]),

        const SizedBox(height: 16),

        // ── Updates ───────────────────────────────────────────────────────
        _SettingsSection(label: L.settingsUpdates, children: [
          SwitchListTile(secondary: const Icon(Icons.notifications_outlined),
            title: Text(L.settingsAutoUpdate),
            subtitle: Text(L.settingsAutoUpdateSub),
            value: _autoUpdate,
            onChanged: (v) async { await _set('ls_auto_update_check', v); setState(() => _autoUpdate = v); }),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: _checkingUpdate
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.system_update_outlined),
            title: Text(L.settingsCheckNow),
            subtitle: _updateError != null
                ? Text(_updateError!, style: TextStyle(color: scheme.error))
                : (_updateInfo == null
                    ? Text(L.settingsUpToDate)
                    : Text(L.settingsUpdateAvailable(_updateInfo!.version))),
            onTap: _checkingUpdate ? null : () => _checkUpdate()),
        ]),

        const SizedBox(height: 16),

        // ── About ─────────────────────────────────────────────────────────
        _SettingsSection(label: L.settingsAbout, children: [
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(L.settingsVersion),
            trailing: Text(UpdateService.currentVersion,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.web_rounded),
            title: Text(L.settingsWebVersion),
            subtitle: Text(L.settingsWebVersionSub),
            trailing: const Icon(Icons.open_in_new_rounded, size: 16),
            onTap: () async {
              final u = Uri.parse('https://sanobld.github.io/LastStats');
              if (await canLaunchUrl(u)) await launchUrl(u, mode: LaunchMode.externalApplication);
            }),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.code_rounded),
            title: Text(L.settingsSourceCode),
            subtitle: Text(L.settingsSourceCodeSub),
            trailing: const Icon(Icons.open_in_new_rounded, size: 16),
            onTap: () async {
              final u = Uri.parse('https://github.com/sanobld/LastStats');
              if (await canLaunchUrl(u)) await launchUrl(u, mode: LaunchMode.externalApplication);
            }),
        ]),

        const SizedBox(height: 24),
        Center(child: Text('LastStats Mobile v${UpdateService.currentVersion}',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
        const SizedBox(height: 8),
      ]),
    );
  }
}


// ── Color picker dialog ───────────────────────────────────────────────────────

class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSLColor _hsl;
  late TextEditingController _hexCtrl;
  bool _hexError = false;

  @override
  void initState() {
    super.initState();
    _hsl = HSLColor.fromColor(widget.initialColor)
        .withSaturation(_clamp01(HSLColor.fromColor(widget.initialColor).saturation, 0.4, 1.0))
        .withLightness(_clamp01(HSLColor.fromColor(widget.initialColor).lightness, 0.3, 0.7));
    _hexCtrl = TextEditingController(text: colorToHex(_hsl.toColor()));
  }

  @override
  void dispose() { _hexCtrl.dispose(); super.dispose(); }

  double _clamp01(double v, double min, double max) => v.clamp(min, max);
  Color  get _color => _hsl.toColor();

  void _syncHex() {
    _hexCtrl.text = colorToHex(_color);
    _hexCtrl.selection = TextSelection.collapsed(offset: _hexCtrl.text.length);
    _hexError = false;
  }

  void _onHexInput(String raw) {
    final hex = raw.trim().replaceAll('#', '');
    if (hex.length != 6) { setState(() => _hexError = true); return; }
    try {
      final c = Color(0xFF000000 | int.parse(hex, radix: 16));
      final hsl = HSLColor.fromColor(c);
      setState(() {
        _hsl = hsl.withSaturation(_clamp01(hsl.saturation, 0.0, 1.0))
                  .withLightness(_clamp01(hsl.lightness, 0.0, 1.0));
        _hexError = false;
      });
    } catch (_) { setState(() => _hexError = true); }
  }

  Widget _buildHueSlider(BuildContext ctx) {
    return LayoutBuilder(builder: (_, constraints) {
      final w = constraints.maxWidth;
      return GestureDetector(
        onTapDown:   (d) => setState(() { _hsl = _hsl.withHue((d.localPosition.dx / w).clamp(0, 1) * 360); _syncHex(); }),
        onPanUpdate: (d) => setState(() { _hsl = _hsl.withHue((d.localPosition.dx / w).clamp(0, 1) * 360); _syncHex(); }),
        child: SizedBox(height: 36, child: Stack(alignment: Alignment.centerLeft, children: [
          ClipRRect(borderRadius: BorderRadius.circular(8),
            child: Container(height: 24, decoration: const BoxDecoration(gradient: LinearGradient(colors: [
              Color(0xFFFF0000), Color(0xFFFF8000), Color(0xFFFFFF00),
              Color(0xFF00FF00), Color(0xFF00FFFF), Color(0xFF0000FF),
              Color(0xFFFF00FF), Color(0xFFFF0000),
            ])))),
          Positioned(
            left: ((_hsl.hue / 360) * w - 12).clamp(0, w - 24),
            child: Container(width: 24, height: 36,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black26, width: 1.5),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [_hsl.withLightness(0.5).withSaturation(1.0).toColor(),
                              _hsl.withLightness(0.5).withSaturation(1.0).toColor()]))),
          ),
        ])),
      );
    });
  }

  Widget _buildSliderRow(String label, double value, double min, double max,
      List<Color> gradientColors, void Function(double) onChanged) {
    return LayoutBuilder(builder: (_, c) => GestureDetector(
      onTapDown:   (d) => setState(() { onChanged(((d.localPosition.dx / c.maxWidth) * (max - min) + min).clamp(min, max)); _syncHex(); }),
      onPanUpdate: (d) => setState(() { onChanged(((d.localPosition.dx / c.maxWidth) * (max - min) + min).clamp(min, max)); _syncHex(); }),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        SizedBox(height: 28, child: Stack(alignment: Alignment.centerLeft, children: [
          ClipRRect(borderRadius: BorderRadius.circular(6),
            child: Container(height: 20, decoration: BoxDecoration(gradient: LinearGradient(colors: gradientColors)))),
          Positioned(
            left: (((value - min) / (max - min)) * c.maxWidth - 10).clamp(0, c.maxWidth - 20),
            child: Container(width: 20, height: 28,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.black26, width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)]))),
        ])),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final pure   = _hsl.withSaturation(1.0).withLightness(0.5).toColor();

    const quickPresets = [
      Color(0xFF7C3AED), Color(0xFF1D4ED8), Color(0xFF059669),
      Color(0xFFDC2626), Color(0xFFD97706), Color(0xFFDB2777),
      Color(0xFF0F766E), Color(0xFFEA580C), Color(0xFF0284C7),
      Color(0xFF16A34A),
    ];

    return AlertDialog(
      title: Text(L.colorPickerTitle),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Container(height: 52,
                decoration: BoxDecoration(color: _color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant)))),
              const SizedBox(width: 10),
              Expanded(child: TextField(
                controller: _hexCtrl, onChanged: _onHexInput,
                decoration: InputDecoration(
                  labelText: 'HEX',
                  errorText: _hexError ? L.colorPickerInvalid : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                style: text.bodyMedium?.copyWith(fontFamily: 'monospace'),
              )),
            ]),
            const SizedBox(height: 16),
            Text(L.colorPickerHue, style: text.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildHueSlider(context),
            const SizedBox(height: 14),
            _buildSliderRow(L.colorPickerSaturation, _hsl.saturation, 0.0, 1.0,
              [Colors.grey.shade400, pure], (v) => _hsl = _hsl.withSaturation(v)),
            const SizedBox(height: 14),
            _buildSliderRow(L.colorPickerBrightness, _hsl.lightness, 0.15, 0.85,
              [Colors.black, _hsl.withSaturation(1.0).withLightness(0.5).toColor(), Colors.white],
              (v) => _hsl = _hsl.withLightness(v)),
            const SizedBox(height: 16),
            Text(L.colorPickerQuickColors, style: text.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8,
              children: quickPresets.map((c) => GestureDetector(
                onTap: () => setState(() { _hsl = HSLColor.fromColor(c); _syncHex(); }),
                child: Container(width: 28, height: 28,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle,
                      border: Border.all(color: scheme.outlineVariant, width: 1))),
              )).toList()),
            const SizedBox(height: 16),
          ],
        )),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(L.commonCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _color), child: Text(L.commonApply)),
      ],
    );
  }
}


// ── Settings section wrapper ──────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String label; final List<Widget> children;
  const _SettingsSection({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(label.toUpperCase(), style: text.labelSmall?.copyWith(
            color: scheme.primary, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
      Card(
        elevation: 0, color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: _cardBorder(scheme)),
        child: Column(children: children)),
    ]);
  }
}

// ── Export sheet ──────────────────────────────────────────────────────────────

class _ExportSheet extends StatefulWidget {
  final String payload, defaultName;
  const _ExportSheet({required this.payload, required this.defaultName});

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  late final TextEditingController _nameCtrl;
  bool _copied = false;

  @override
  void initState() { super.initState(); _nameCtrl = TextEditingController(text: widget.defaultName); }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.payload));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _copied = false); });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75, minChildSize: 0.4, maxChildSize: 0.95, expand: false,
      builder: (ctx, sc) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Scaffold(
          body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(child: Container(
                    width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )),
                  Row(children: [
                    Icon(Icons.upload_rounded, color: scheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(L.exportTitle, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  ]),
                ])),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(child: ListView(controller: sc, padding: const EdgeInsets.all(20), children: [
              Text(L.exportFilename,
                  style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.insert_drive_file_outlined), suffixText: '.json',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              Text(L.exportJsonContent,
                  style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5))),
                constraints: const BoxConstraints(maxHeight: 220),
                child: SingleChildScrollView(padding: const EdgeInsets.all(12),
                  child: SelectableText(widget.payload,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: scheme.onSurfaceVariant))),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.info_outline_rounded, size: 13, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(child: Text(L.exportInfo, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
              ]),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _copy,
                icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded),
                label: Text(_copied ? L.exportCopied : L.exportCopy),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: _copied ? Colors.green.shade600 : null,
                ),
              ),
            ])),
          ]),
        ),
      ),
    );
  }
}