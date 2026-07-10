import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';
import '../l10n/l10n.dart';
import '../supported_locales.dart';
import '../services/lastfm_service.dart';
import '../services/data_cache.dart';
import '../services/prefetch_service.dart';
import '../services/backup_service.dart';
import '../services/favorites_auth.dart';
import 'home_screen.dart';
import 'onboarding_flow.dart';

// ══════════════════════════════════════════════════════════════════════════
//  SetupScreen — credentials entry (animated redesign)
// ══════════════════════════════════════════════════════════════════════════

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with TickerProviderStateMixin {

  final _usernameCtrl = TextEditingController();
  final _apikeyCtrl   = TextEditingController();
  final _secretCtrl   = TextEditingController();

  bool    _obscureApiKey   = true;
  bool    _obscureSecret   = true;
  bool    _enableFavorites = false;
  bool    _rememberMe      = true;
  bool    _isLoading       = false;
  String? _errorMessage;

  // ── Animation controllers ──────────────────────────────────────────────
  late final AnimationController _entryCtrl; // staggered page entry (once)
  late final AnimationController _floatCtrl; // continuous logo float

  // Entry animations (driven by _entryCtrl 0→1 over 900 ms)
  late final Animation<double> _langFade;
  late final Animation<Offset> _langSlide;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _footerFade;

  // Continuous float offset in pixels (driven by _floatCtrl)
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    localeNotifier.addListener(_onLocale);

    // Entry animation — runs once on open
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _langFade  = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut));
    _langSlide = Tween<Offset>(begin: const Offset(0, -0.6), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic)));

    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl,
            curve: const Interval(0.1, 0.65, curve: Curves.easeOutBack)));
    _logoFade  = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.1, 0.55, curve: Curves.easeOut));

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.14), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl,
            curve: const Interval(0.35, 0.95, curve: Curves.easeOutCubic)));
    _cardFade  = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOut));

    _footerFade = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.62, 1.0, curve: Curves.easeOut));

    _entryCtrl.forward();

    // Logo float — 2.6 s, repeating
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -5.5, end: 5.5).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_onLocale);
    _usernameCtrl.dispose();
    _apikeyCtrl.dispose();
    _secretCtrl.dispose();
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  void _onLocale() => setState(() {});

  Future<void> _setLocale(String code) async {
    localeNotifier.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ls_locale', code);
  }

  // Opens a scrollable bottom sheet listing every supported language.
  // Handles 50+ languages gracefully (unlike a row/wrap of chips).
  void _openLanguageSheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(children: [
                  Text(L.settingsLanguage,
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ]),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: kSupportedLocales.length,
                  itemBuilder: (_, i) {
                    final lang     = kSupportedLocales[i];
                    final selected = localeNotifier.value == lang.code;
                    return ListTile(
                      onTap: () { _setLocale(lang.code); Navigator.pop(sheetContext); },
                      leading: Text(lang.flag, style: const TextStyle(fontSize: 22)),
                      title: Text(lang.nativeName,
                          style: text.bodyLarge?.copyWith(
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                      subtitle: Text(lang.englishName,
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      trailing: selected
                          ? Icon(Icons.check_rounded, color: scheme.primary)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Restore a real backup .json file (picked via the native file dialog)
  // and fill the username/api key fields — replaces the old copy-paste flow.
  bool _restoring = false;

  Future<void> _restoreFromFile() async {
    setState(() { _restoring = true; _errorMessage = null; });
    final result = await BackupService.importFromFile();
    if (!mounted) return;
    setState(() => _restoring = false);

    if (result == null) return; // picker cancelled
    if (!result.success || (result.username ?? '').isEmpty || (result.apiKey ?? '').isEmpty) {
      setState(() => _errorMessage = L.importInvalidFormat);
      return;
    }
    setState(() {
      _usernameCtrl.text = result.username!;
      _apikeyCtrl.text   = result.apiKey!;
      _errorMessage      = null;
    });
  }

  // Validate + connect
  Future<void> _launch() async {
    final username = _usernameCtrl.text.trim();
    final apiKey   = _apikeyCtrl.text.trim();

    if (username.isEmpty || apiKey.isEmpty) {
      setState(() => _errorMessage = localeNotifier.value == 'en'
          ? 'Please fill both fields.' : 'Remplis les deux champs.');
      return;
    }
    if (apiKey.length != 32) {
      setState(() => _errorMessage = localeNotifier.value == 'en'
          ? 'API key must be 32 characters.' : 'La clé API doit faire 32 caractères.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final service  = LastFmService(apiKey: apiKey, username: username);
      final userInfo = await service.getUserInfo();

      if (userInfo == null) throw Exception(
          localeNotifier.value == 'en' ? 'Profile not found.' : 'Profil introuvable.');

      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ls_username', username);
        await prefs.setString('ls_apikey',   apiKey);
      }

      final totalScrobbles =
          int.tryParse(userInfo['playcount']?.toString() ?? '0') ?? 0;

      // Optional: authorize favorites (loved tracks) — doesn't block setup on failure.
      if (_enableFavorites && _secretCtrl.text.trim().isNotEmpty) {
        if (!mounted) return;
        await connectFavorites(
          context, username: username, apiKey: apiKey, secret: _secretCtrl.text,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => _FirstLoadScreen(
            username:       username,
            apiKey:         apiKey,
            service:        service,
            totalScrobbles: totalScrobbles,
          ),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    final size   = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Soft decorative blobs behind everything
          _SetupBackground(scheme: scheme, size: size),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      // ── Language selector — compact dropdown button ─────
                      // Scales cleanly to 50+ languages: shows only the
                      // current selection, opens a scrollable sheet on tap
                      // instead of laying out every option at once.
                      SlideTransition(
                        position: _langSlide,
                        child: FadeTransition(
                          opacity: _langFade,
                          child: Align(
                            alignment: Alignment.center,
                            child: _LangSelectorButton(
                              current: supportedLocaleFor(localeNotifier.value),
                              scheme: scheme, text: text,
                              onTap: () => _openLanguageSheet(context),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 44),

                      // ── Logo — scale entry + glow + continuous float ─────
                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: AnimatedBuilder(
                            animation: _floatAnim,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(0, _floatAnim.value),
                              child: child,
                            ),
                            child: Column(children: [
                              // Icon with primary color glow
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: scheme.primary.withValues(alpha: 0.30),
                                      blurRadius: 40,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.asset(
                                    'assets/images/icon-512.png',
                                    width: 90, height: 90, fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 90, height: 90,
                                      decoration: BoxDecoration(
                                        color: scheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Icon(Icons.headphones_rounded,
                                          size: 46,
                                          color: scheme.onPrimaryContainer),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'LastStats',
                                style: text.headlineLarge?.copyWith(
                                  fontWeight:    FontWeight.w800,
                                  color:         scheme.primary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                L.setupTagline,
                                style: text.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant),
                              ),
                            ]),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Main card — slide up + fade ─────────────────────
                      SlideTransition(
                        position: _cardSlide,
                        child: FadeTransition(
                          opacity: _cardFade,
                          child: Card(
                            elevation: 0,
                            color: scheme.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28)),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Card header with icon badge
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        color: scheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.person_search_rounded,
                                          size: 20,
                                          color: scheme.onPrimaryContainer),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      L.setupAnalyseProfile,
                                      style: text.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ]),
                                  const SizedBox(height: 24),

                                  // Username field
                                  TextField(
                                    controller:      _usernameCtrl,
                                    textInputAction: TextInputAction.next,
                                    autocorrect:     false,
                                    decoration: InputDecoration(
                                      labelText: L.setupUsernameLabel,
                                      prefixIcon: const Icon(
                                          Icons.person_outline_rounded),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14)),
                                      filled:    true,
                                      fillColor: scheme.surface,
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // API key field
                                  TextField(
                                    controller:        _apikeyCtrl,
                                    textInputAction:   TextInputAction.done,
                                    obscureText:       _obscureApiKey,
                                    autocorrect:       false,
                                    enableSuggestions: false,
                                    onSubmitted:       (_) => _launch(),
                                    decoration: InputDecoration(
                                      labelText: L.setupApiKeyLabel,
                                      hintText: L.setupApiKeyHint,
                                      prefixIcon: const Icon(Icons.key_rounded),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscureApiKey
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined),
                                        onPressed: () => setState(
                                            () => _obscureApiKey = !_obscureApiKey),
                                      ),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14)),
                                      filled:    true,
                                      fillColor: scheme.surface,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Security hint
                                  Row(children: [
                                    Icon(Icons.shield_outlined,
                                        size: 14, color: scheme.onSurfaceVariant),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(
                                      L.setupApiKeyPrivacyNote,
                                      style: text.bodySmall?.copyWith(
                                          color: scheme.onSurfaceVariant),
                                    )),
                                  ]),
                                  const SizedBox(height: 4),

                                  // Optional favorites (secret key) section
                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => setState(
                                        () => _enableFavorites = !_enableFavorites),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(children: [
                                        Checkbox(
                                          value: _enableFavorites,
                                          onChanged: (v) => setState(
                                              () => _enableFavorites = v ?? false),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4)),
                                        ),
                                        Expanded(child: Text(
                                          L.setupEnableFavorites,
                                          style: text.bodySmall,
                                        )),
                                      ]),
                                    ),
                                  ),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 220),
                                    child: !_enableFavorites
                                        ? const SizedBox.shrink()
                                        : Padding(
                                            padding: const EdgeInsets.only(top: 2, bottom: 10),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  L.setupFavoritesExplain,
                                                  style: text.bodySmall?.copyWith(
                                                      color: scheme.onSurfaceVariant),
                                                ),
                                                const SizedBox(height: 10),
                                                TextField(
                                                  controller:        _secretCtrl,
                                                  obscureText:       _obscureSecret,
                                                  autocorrect:       false,
                                                  enableSuggestions: false,
                                                  decoration: InputDecoration(
                                                    labelText: L.setupSecretKeyLabel,
                                                    prefixIcon: const Icon(Icons.favorite_border_rounded),
                                                    suffixIcon: IconButton(
                                                      icon: Icon(_obscureSecret
                                                          ? Icons.visibility_outlined
                                                          : Icons.visibility_off_outlined),
                                                      onPressed: () => setState(
                                                          () => _obscureSecret = !_obscureSecret),
                                                    ),
                                                    border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(14)),
                                                    filled:    true,
                                                    fillColor: scheme.surface,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Remember me
                                  Row(children: [
                                    Checkbox(
                                      value:     _rememberMe,
                                      onChanged: (v) => setState(
                                          () => _rememberMe = v ?? true),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4)),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(
                                          () => _rememberMe = !_rememberMe),
                                      child: Text(L.setupRememberMe),
                                    ),
                                  ]),
                                  const SizedBox(height: 20),

                                  // Launch button
                                  FilledButton.icon(
                                    onPressed: _isLoading ? null : _launch,
                                    icon: _isLoading
                                        ? SizedBox(
                                            width: 18, height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: scheme.onPrimary))
                                        : const Icon(Icons.bar_chart_rounded),
                                    label: Text(_isLoading
                                        ? L.setupConnecting
                                        : L.setupStartAnalysis),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),

                                  // Error block — with AnimatedSize
                                  if (_errorMessage != null) ...[
                                    const SizedBox(height: 16),
                                    AnimatedSize(
                                      duration: const Duration(milliseconds: 250),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: scheme.errorContainer,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(children: [
                                          Icon(Icons.warning_amber_rounded,
                                              color: scheme.onErrorContainer,
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(
                                            _errorMessage!,
                                            style: text.bodySmall?.copyWith(
                                                color: scheme.onErrorContainer),
                                          )),
                                        ]),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Footer (divider + JSON + API link) — last to fade ─
                      FadeTransition(
                        opacity: _footerFade,
                        child: Column(children: [

                          // "or" divider
                          Row(children: [
                            Expanded(child: Divider(color: scheme.outlineVariant)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(L.setupOr,
                                  style: text.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant)),
                            ),
                            Expanded(child: Divider(color: scheme.outlineVariant)),
                          ]),
                          const SizedBox(height: 16),

                          // Restore from backup file (real file picker)
                          Card(
                            elevation: 0,
                            color: scheme.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(children: [
                                    Icon(Icons.upload_file_rounded,
                                        size: 20, color: scheme.primary),
                                    const SizedBox(width: 8),
                                    Text(L.setupRestoreBackup,
                                        style: text.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700)),
                                  ]),
                                  const SizedBox(height: 8),
                                  Text(L.setupRestoreBackupSub,
                                      style: text.bodySmall?.copyWith(
                                          color: scheme.onSurfaceVariant)),
                                  const SizedBox(height: 16),

                                  OutlinedButton.icon(
                                    onPressed: _restoring ? null : _restoreFromFile,
                                    icon: _restoring
                                        ? const SizedBox(width: 16, height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Icon(Icons.folder_open_rounded, size: 18),
                                    label: Text(L.backupChooseFile),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Last.fm API key link
                          Center(
                            child: TextButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse(
                                    'https://www.last.fm/api/account/create');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.open_in_new_rounded, size: 16),
                              label: Text(L.setupGetApiKey),
                            ),
                          ),

                          const SizedBox(height: 16),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Two soft decorative blobs behind the UI ───────────────────────────────────
class _SetupBackground extends StatelessWidget {
  final ColorScheme scheme;
  final Size        size;

  const _SetupBackground({required this.scheme, required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Top-right blob (primary color, very low opacity)
      Positioned(
        top:   -size.height * 0.10,
        right: -size.width  * 0.20,
        child: Container(
          width:  size.width * 0.72,
          height: size.width * 0.72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary.withValues(alpha: 0.07),
          ),
        ),
      ),
      // Bottom-left blob (tertiary color, very low opacity)
      Positioned(
        bottom: -size.height * 0.08,
        left:   -size.width  * 0.25,
        child: Container(
          width:  size.width * 0.65,
          height: size.width * 0.65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.tertiary.withValues(alpha: 0.06),
          ),
        ),
      ),
    ]);
  }
}

// ── Language selector button — shows current pick, opens a sheet ──────────────
class _LangSelectorButton extends StatelessWidget {
  final SupportedLocale current;
  final ColorScheme     scheme;
  final TextTheme       text;
  final VoidCallback    onTap;

  const _LangSelectorButton({
    required this.current,
    required this.scheme,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(current.flag, style: const TextStyle(fontSize: 17)),
            const SizedBox(width: 8),
            Text(
              current.nativeName,
              style: text.labelLarge?.copyWith(
                color:       scheme.onSurface,
                fontWeight:  FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.expand_more_rounded, size: 18, color: scheme.onSurfaceVariant),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _FirstLoadScreen — shown ONCE on first login
//
//  • Listens to PrefetchService.progressNotifier for real-time steps
//  • Checklist: ✓ done, ⏳ active, animated progress bar
//  • Welcome banner slides + fades in when loading is complete,
//    text in the chosen language (FR: "Bienvenue sur LastStats !"
//                                  EN: "Welcome to LastStats!")
//  • Navigates to HomeScreen 1.6 s after completion (time to read banner)
// ══════════════════════════════════════════════════════════════════════════

class _FirstLoadScreen extends StatefulWidget {
  final String        username;
  final String        apiKey;
  final LastFmService service;
  final int           totalScrobbles;

  const _FirstLoadScreen({
    required this.username,
    required this.apiKey,
    required this.service,
    required this.totalScrobbles,
  });

  @override
  State<_FirstLoadScreen> createState() => _FirstLoadScreenState();
}

class _FirstLoadScreenState extends State<_FirstLoadScreen>
    with TickerProviderStateMixin {

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fade;
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulse;

  // Welcome banner — triggered once when isComplete
  late final AnimationController _welcomeCtrl;
  late final Animation<double>   _welcomeScale;
  late final Animation<double>   _welcomeFade;

  PrefetchState _state = const PrefetchState(
    currentStep: '', fraction: 0, completedSteps: [], isComplete: false,
  );
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Page fade-in
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Pulsing icon
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Welcome banner (scale-in + fade-in on completion)
    _welcomeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _welcomeScale = Tween<double>(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(parent: _welcomeCtrl, curve: Curves.easeOutBack));
    _welcomeFade  = CurvedAnimation(
        parent: _welcomeCtrl, curve: Curves.easeOut);

    PrefetchService.progressNotifier.addListener(_onProgress);
    PrefetchService.prefetchAllWithProgress(widget.service, force: true);
  }

  void _onProgress() {
    if (!mounted) return;
    setState(() => _state = PrefetchService.progressNotifier.value);
    if (_state.isComplete) {
      _welcomeCtrl.forward(); // play welcome banner animation
      _scheduleNavigation();
    }
  }

  void _scheduleNavigation() {
    if (_navigated) return;
    _navigated = true;
    // Longer delay so the user can read the welcome banner
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => OnboardingFlow(
            username: widget.username,
            apiKey:   widget.apiKey,
          ),
          transitionsBuilder: (_, anim, __, child) {
            final curved = CurvedAnimation(
                parent: anim, curve: Curves.easeOutCubic);
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.06),
                end:   Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 550),
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    _welcomeCtrl.dispose();
    PrefetchService.progressNotifier.removeListener(_onProgress);
    super.dispose();
  }

  String _t(String fr, String en) =>
      localeNotifier.value == 'en' ? en : fr;

  static String _fmtLarge(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;


    return Scaffold(
      backgroundColor: scheme.surface,
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height
                           - MediaQuery.of(context).padding.top
                           - MediaQuery.of(context).padding.bottom
                           - 48,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    const Spacer(flex: 2),

                    // ── Pulsing icon ──────────────────────────────────────
                    ScaleTransition(
                      scale: _pulse,
                      child: Container(
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color:        scheme.primary.withValues(alpha: 0.22),
                              blurRadius:   28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(Icons.headphones_rounded,
                            size: 44, color: scheme.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── App name ──────────────────────────────────────────
                    Text('LastStats',
                        style: text.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.primary)),
                    const SizedBox(height: 6),

                    // ── "Welcome, username!" ──────────────────────────────
                    Text(
                      L.setupWelcome(widget.username),
                      style: text.titleMedium?.copyWith(
                          color:      scheme.onSurface,
                          fontWeight: FontWeight.w600),
                    ),

                    // ── Scrobble count badge ──────────────────────────────
                    if (widget.totalScrobbles > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color:        scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.library_music_rounded,
                              size: 14, color: scheme.onSecondaryContainer),
                          const SizedBox(width: 7),
                          Text(
                            L.setupScrobblesToImport(_fmtLarge(widget.totalScrobbles)),
                            style: text.labelMedium?.copyWith(
                                color:      scheme.onSecondaryContainer,
                                fontWeight: FontWeight.w700),
                          ),
                        ]),
                      ),
                    ],

                    const Spacer(flex: 2),

                    // ── Animated checklist ────────────────────────────────
                    _FirstLoadChecklist(
                      state:  _state,
                      scheme: scheme,
                      text:   text,
                      t:      _t,
                    ),
                    const SizedBox(height: 22),

                    // ── Progress bar ──────────────────────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: _state.fraction),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => LinearProgressIndicator(
                          value:           v,
                          minHeight:       7,
                          backgroundColor: scheme.surfaceContainerHigh,
                          valueColor:
                              AlwaysStoppedAnimation(scheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Current step label (below bar) ────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: Text(
                        _state.isComplete
                            ? _t('✨ Import terminé !', '✨ Import complete!')
                            : _state.currentStep.isEmpty
                                ? _t('Connexion à Last.fm…',
                                     'Connecting to Last.fm…')
                                : _state.currentStep,
                        key: ValueKey(
                            _state.isComplete ? 'done' : _state.currentStep),
                        style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Welcome banner — animates in when loading is done ──
                    // Written in the chosen language (FR / EN)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      child: _state.isComplete
                          ? FadeTransition(
                              opacity: _welcomeFade,
                              child: ScaleTransition(
                                scale: _welcomeScale,
                                child: Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 18),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        scheme.primaryContainer,
                                        scheme.secondaryContainer,
                                      ],
                                      begin: Alignment.topLeft,
                                      end:   Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: scheme.primary
                                            .withValues(alpha: 0.18),
                                        blurRadius:   24,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.music_note_rounded,
                                          color: scheme.primary, size: 26),
                                      const SizedBox(width: 10),
                                      Text(
                                        L.setupWelcomeBanner,
                                        style: text.titleMedium?.copyWith(
                                          color:      scheme.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const Spacer(flex: 1),

                    // ── One-time import note ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color:        scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: scheme.outlineVariant
                                .withValues(alpha: 0.5)),
                      ),
                      child: Row(children: [
                        Icon(Icons.bolt_rounded,
                            size: 15, color: scheme.tertiary),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          L.setupOneTimeImportNote,
                          style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _FirstLoadChecklist — animated step list
// ══════════════════════════════════════════════════════════════════════════

class _FirstLoadChecklist extends StatefulWidget {
  final PrefetchState state;
  final ColorScheme   scheme;
  final TextTheme     text;
  final String Function(String fr, String en) t;

  const _FirstLoadChecklist({
    required this.state,
    required this.scheme,
    required this.text,
    required this.t,
  });

  @override
  State<_FirstLoadChecklist> createState() => _FirstLoadChecklistState();
}

class _FirstLoadChecklistState extends State<_FirstLoadChecklist> {
  final _sc = ScrollController();

  @override
  void didUpdateWidget(_FirstLoadChecklist old) {
    super.didUpdateWidget(old);
    // Auto-scroll to bottom on each new step
    if (widget.state.completedSteps.length != old.state.completedSteps.length ||
        widget.state.currentStep != old.state.currentStep) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_sc.hasClients) {
          _sc.animateTo(
            _sc.position.maxScrollExtent,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state      = widget.state;
    final scheme     = widget.scheme;
    final text       = widget.text;
    final t          = widget.t;
    final hasContent = state.completedSteps.isNotEmpty ||
        state.currentStep.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 340),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: hasContent
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fixed header
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    t('Import de tes données', 'Importing your data'),
                    style: text.labelMedium?.copyWith(
                      color:         scheme.onSurfaceVariant,
                      fontWeight:    FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                // Scrollable steps
                Flexible(
                  child: ListView(
                    controller: _sc,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      // Done steps
                      ...state.completedSteps.map((label) => _StepRow(
                        label:  label,
                        status: _RowStatus.done,
                        scheme: scheme,
                        text:   text,
                      )),

                      // Active step
                      if (state.currentStep.isNotEmpty && !state.isComplete)
                        _StepRow(
                          label:  state.currentStep,
                          status: _RowStatus.active,
                          scheme: scheme,
                          text:   text,
                        ),

                      // Completion line
                      if (state.isComplete)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(children: [
                            Icon(Icons.rocket_launch_rounded,
                                size: 15, color: scheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              t('Importé !', 'Imported!'),
                              style: text.bodySmall?.copyWith(
                                  color:      scheme.primary,
                                  fontWeight: FontWeight.w700),
                            ),
                          ]),
                        ),
                    ],
                  ),
                ),
              ],
            )
          // Placeholder before first step
          : Row(children: [
              SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                  strokeWidth:  2.2,
                  valueColor: AlwaysStoppedAnimation(scheme.primary),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                t('Connexion à Last.fm…', 'Connecting to Last.fm…'),
                style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant),
              ),
            ]),
    );
  }
}

enum _RowStatus { done, active }

class _StepRow extends StatelessWidget {
  final String      label;
  final _RowStatus  status;
  final ColorScheme scheme;
  final TextTheme   text;

  const _StepRow({
    required this.label,
    required this.status,
    required this.scheme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = status == _RowStatus.done;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        // Status icon with switch animation
        SizedBox(
          width: 18, height: 18,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: isDone
                ? Icon(Icons.check_circle_rounded,
                    size: 18, color: scheme.primary,
                    key: const ValueKey('done'))
                : CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(scheme.primary),
                    key: const ValueKey('active')),
          ),
        ),
        const SizedBox(width: 10),

        // Label
        Expanded(
          child: Text(
            label,
            style: text.bodyMedium?.copyWith(
              color:      isDone ? scheme.onSurface : scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Secondary check for done steps
        if (isDone)
          Icon(Icons.check_rounded,
              size: 14,
              color: scheme.primary.withValues(alpha: 0.6)),
      ]),
    );
  }
}