import 'package:flutter/material.dart';
import '../widgets/skeleton.dart';
import '../theme/m3_motion.dart';
import '../theme/m3_shapes.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';
import '../l10n/l10n.dart';
import '../l10n/extra_strings.dart';
import '../supported_locales.dart';
import '../services/lastfm_service.dart';
import '../widgets/m3_components.dart';
import '../services/backup_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'settings/lastfm_login_page.dart';
import '../services/favorites_auth.dart';
import '../services/internal_keys.dart';
import 'onboarding_flow.dart';

// ══════════════════════════════════════════════════════════════════════════
//  SetupScreen — credentials entry (animated redesign)
// ══════════════════════════════════════════════════════════════════════════

/// Picks the self-contained logo SVG (own background baked in) matching the
/// current theme family (Nothing red-dot vs plain mono) and brightness.
String _logoAsset(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final nothing = themeStyleNotifier.value == 'nothing';
  final family = nothing ? 'app_logo_nothing' : 'app_logo';
  return 'assets/icons/${family}_${dark ? 'black_bg' : 'white_bg'}.svg';
}

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
  final _displayNameCtrl = TextEditingController();

  bool    _obscureApiKey   = true;
  bool    _obscureSecret   = true;
  bool    _enableFavorites = false;
  bool    _useInternalKey  = false;
  int     _method          = 0; // 0 own key, 1 built-in key, 2 Last.fm website
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
      duration: const Duration(milliseconds: 1100),
    );

    _langFade  = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.0, 0.45, curve: M3Motion.emphasizedDecelerate));
    _langSlide = Tween<Offset>(begin: const Offset(0, -0.6), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl,
            curve: const Interval(0.0, 0.5, curve: M3Motion.emphasizedDecelerate)));

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl,
            curve: const Interval(0.05, 0.75, curve: M3Motion.spatialDefault)));
    _logoFade  = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.1, 0.55, curve: M3Motion.emphasizedDecelerate));

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl,
            curve: const Interval(0.30, 0.95, curve: M3Motion.spatialDefault)));
    _cardFade  = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.35, 0.85, curve: M3Motion.emphasizedDecelerate));

    _footerFade = CurvedAnimation(parent: _entryCtrl,
        curve: const Interval(0.62, 1.0, curve: M3Motion.emphasizedDecelerate));

    _entryCtrl.forward();

    // Logo float — 2.6 s, repeating
    // The cookie behind the logo turns slowly (replaces the old floating).
    // Skipped when the system asks for reduced animations.
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    );
    if (!WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
        .disableAnimations) {
      _floatCtrl.repeat();
    }
    _floatAnim = Tween<double>(begin: 0, end: 1).animate(_floatCtrl);
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_onLocale);
    _usernameCtrl.dispose();
    _apikeyCtrl.dispose();
    _secretCtrl.dispose();
    _displayNameCtrl.dispose();
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
    sheetAnimationStyle: kM3SheetAnimation,
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
      _useInternalKey    = false;
      _method            = 0;
      _errorMessage      = null;
      // Reflect a restored secret key in the UI too, not just prefs,
      // so the user can see/verify it before launching.
      if (secretKeyNotifier.value.isNotEmpty) {
        _secretCtrl.text   = secretKeyNotifier.value;
        _enableFavorites   = true;
      }
    });
  }

  // Phones only: the Last.fm website login runs in a WebView.
  bool get _canWebLogin =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  // Log in on the Last.fm website, then connect with the built-in key.
  Future<void> _lastfmWeb() async {
    final name = await LastfmLoginPage.open(context);
    if (name == null || !mounted) return;
    setState(() {
      _usernameCtrl.text = name;
      _useInternalKey = true;
      _errorMessage = null;
    });
    await _launch();
  }

  // Validate + connect
  Future<void> _launch() async {
    final username = _usernameCtrl.text.trim();
    final apiKey   = _useInternalKey
        ? await InternalKeys.pick()
        : _apikeyCtrl.text.trim();

    if (username.isEmpty || apiKey.isEmpty) {
      setState(() => _errorMessage = tx('ui_please_fill_both_field'));
      return;
    }
    if (!_useInternalKey && apiKey.length != 32) {
      setState(() => _errorMessage = tx('ui_api_key_must_be_32_cha'));
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final service  = LastFmService(apiKey: apiKey, username: username);
      final userInfo = await service.getUserInfo();

      if (userInfo == null) {
        throw Exception(
          tx('ui_profile_not_found'));
      }

      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ls_username', username);
        await prefs.setString('ls_apikey',   apiKey);
      } else {
        // A backup import (if used) writes credentials to disk straight
        // away, regardless of this checkbox — clear them here so "don't
        // remember me" is actually honored. In-memory notifiers are left
        // untouched, so favorites still work for the current session.
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('ls_username');
        await prefs.remove('ls_apikey');
        await prefs.remove('ls_secret_key');
        await prefs.remove('ls_session_key');
      }

      // Custom display name (optional) — stored regardless of "remember
      // me", same as the other appearance/behavior prefs.
      final customName = _displayNameCtrl.text.trim();
      if (customName.isNotEmpty) {
        displayNameNotifier.value = customName;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ls_display_name', customName);
      }

      // Optional: authorize favorites (loved tracks) — doesn't block setup on failure.
      if (!_useInternalKey && _enableFavorites && _secretCtrl.text.trim().isNotEmpty) {
        if (!mounted) return;
        await connectFavorites(
          context, username: username, apiKey: apiKey, secret: _secretCtrl.text,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        M3FadeThroughRoute<void>(
          builder: (_) => OnboardingFlow(
            username: username,
            apiKey:   apiKey,
          ),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Filled rounded field, same look for every input of the screen.
  InputDecoration _dec(ColorScheme scheme, String label, IconData icon,
      {String? hint, Widget? suffix}) {
    OutlineInputBorder b(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: c == Colors.transparent
            ? BorderSide.none
            : BorderSide(color: c, width: w));
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: b(Colors.transparent, 0),
      enabledBorder: b(Colors.transparent, 0),
      focusedBorder: b(scheme.primary, 2),
    );
  }

  // Fade + slide up, driven by one entry animation.
  Widget _in(Animation<double> a, Widget child, [double dy = 0.08]) =>
      FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween<Offset>(begin: Offset(0, dy), end: Offset.zero)
              .animate(a),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final size   = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          _SetupBackground(scheme: scheme, size: size, spin: _floatAnim),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Language pill (top right) ──
                      SlideTransition(
                        position: _langSlide,
                        child: FadeTransition(
                          opacity: _langFade,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _LangSelectorButton(
                              current: supportedLocaleFor(localeNotifier.value),
                              scheme: scheme, text: text,
                              onTap: () => _openLanguageSheet(context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Hero: logo on a slowly turning cookie ──
                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Column(children: [
                            SizedBox(
                              width: 140, height: 140,
                              child: Stack(alignment: Alignment.center, children: [
                                RotationTransition(
                                  turns: _floatAnim,
                                  child: Container(
                                    width: 140, height: 140,
                                    decoration: ShapeDecoration(
                                      color: scheme.primaryContainer,
                                      shape: const M3CookieBorder(
                                          lobes: 9, amplitude: 0.07),
                                    ),
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: SvgPicture.asset(_logoAsset(context),
                                      width: 76, height: 76),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 14),
                            Text('LastStats',
                                style: text.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.primary,
                                  letterSpacing: -1,
                                )),
                            const SizedBox(height: 4),
                            Text(L.setupTagline,
                                textAlign: TextAlign.center,
                                style: text.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Welcome + connection card ──
                      SlideTransition(
                        position: _cardSlide,
                        child: FadeTransition(
                          opacity: _cardFade,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(tx('wl_title'),
                                    style: text.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(tx('wl_sub'),
                                    style: text.bodyMedium?.copyWith(
                                        color: scheme.onSurfaceVariant)),
                                const SizedBox(height: 18),

                                // Connection method tiles
                                _MethodTile(
                                  selected: _method == 0,
                                  icon: Icons.key_rounded,
                                  title: '${tx('sm_key_t')} (${tx('rec')})',
                                  subtitle: tx('sm_key_s'),
                                  onTap: () => setState(() {
                                    _method = 0; _useInternalKey = false;
                                  }),
                                ),
                                const SizedBox(height: 8),
                                _MethodTile(
                                  selected: _method == 1,
                                  icon: Icons.bolt_rounded,
                                  title: tx('sm_builtin_t'),
                                  subtitle: tx('sm_builtin_s'),
                                  onTap: () => setState(() {
                                    _method = 1; _useInternalKey = true;
                                  }),
                                ),
                                if (_canWebLogin) ...[
                                  const SizedBox(height: 8),
                                  _MethodTile(
                                    selected: _method == 2,
                                    icon: Icons.login_rounded,
                                    title: '${tx('conn_lfm_web')} (${tx('not_rec')})',
                                    subtitle: tx('lfm_web_sub'),
                                    onTap: () => setState(() {
                                      _method = 2; _useInternalKey = true;
                                    }),
                                  ),
                                ],
                                const SizedBox(height: 18),

                                // Fields (they grow / shrink with the method)
                                AnimatedSize(
                                  duration: M3Motion.spatialFastDuration,
                                  curve: M3Motion.emphasized,
                                  alignment: Alignment.topCenter,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (_method != 2) ...[
                                        TextField(
                                          controller: _usernameCtrl,
                                          textInputAction: TextInputAction.next,
                                          autocorrect: false,
                                          decoration: _dec(scheme,
                                              L.setupUsernameLabel,
                                              Icons.person_outline_rounded),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      TextField(
                                        controller: _displayNameCtrl,
                                        textInputAction: TextInputAction.next,
                                        decoration: _dec(scheme,
                                            L.settingsDisplayNameLabel,
                                            Icons.badge_outlined,
                                            hint: L.settingsDisplayNameHint),
                                      ),
                                      if (!_useInternalKey) ...[
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: _apikeyCtrl,
                                          onChanged: (_) => setState(() {}),
                                          textInputAction: TextInputAction.done,
                                          obscureText: _obscureApiKey,
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          onSubmitted: (_) => _launch(),
                                          decoration: _dec(scheme,
                                            L.setupApiKeyLabel, Icons.key_rounded,
                                            hint: L.setupApiKeyHint,
                                            suffix: IconButton(
                                              icon: Icon(_obscureApiKey
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined),
                                              onPressed: () => setState(() =>
                                                  _obscureApiKey = !_obscureApiKey),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(children: [
                                          Icon(Icons.shield_outlined, size: 14,
                                              color: scheme.onSurfaceVariant),
                                          const SizedBox(width: 6),
                                          Expanded(child: Text(
                                            L.setupApiKeyPrivacyNote,
                                            style: text.bodySmall?.copyWith(
                                                color: scheme.onSurfaceVariant),
                                          )),
                                        ]),
                                        const SizedBox(height: 4),
                                        // Optional favorites (secret key)
                                        SwitchListTile(
                                          contentPadding: EdgeInsets.zero,
                                          value: _enableFavorites,
                                          onChanged: (v) => setState(
                                              () => _enableFavorites = v),
                                          title: Text(L.setupEnableFavorites,
                                              style: text.bodyMedium),
                                        ),
                                        AnimatedSize(
                                          duration: M3Motion.spatialFastDuration,
                                          curve: M3Motion.emphasized,
                                          alignment: Alignment.topCenter,
                                          child: !_enableFavorites
                                              ? const SizedBox(width: double.infinity)
                                              : Padding(
                                                  padding: const EdgeInsets.only(bottom: 8),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(L.setupFavoritesExplain,
                                                          style: text.bodySmall?.copyWith(
                                                              color: scheme.onSurfaceVariant)),
                                                      const SizedBox(height: 10),
                                                      TextField(
                                                        controller: _secretCtrl,
                                                        obscureText: _obscureSecret,
                                                        autocorrect: false,
                                                        enableSuggestions: false,
                                                        decoration: _dec(scheme,
                                                          L.setupSecretKeyLabel,
                                                          Icons.favorite_border_rounded,
                                                          suffix: IconButton(
                                                            icon: Icon(_obscureSecret
                                                                ? Icons.visibility_outlined
                                                                : Icons.visibility_off_outlined),
                                                            onPressed: () => setState(() =>
                                                                _obscureSecret = !_obscureSecret),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        ),
                                      ],
                                      SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        value: _rememberMe,
                                        onChanged: (v) =>
                                            setState(() => _rememberMe = v),
                                        title: Text(L.setupRememberMe,
                                            style: text.bodyMedium),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Main button
                                SizedBox(
                                  height: 56,
                                  child: FilledButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : (_method == 2 ? _lastfmWeb : _launch),
                                    icon: _isLoading
                                        ? SizedBox(
                                            width: 20, height: 20,
                                            child: M3Spinner(color: scheme.onPrimary))
                                        : Icon(_method == 2
                                            ? Icons.login_rounded
                                            : Icons.arrow_forward_rounded),
                                    label: Text(_isLoading
                                        ? L.setupConnecting
                                        : (_method == 2
                                            ? tx('conn_lfm_web')
                                            : tx('conn_connect'))),
                                    style: FilledButton.styleFrom(
                                      shape: const StadiumBorder(),
                                      textStyle: text.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),

                                // Error message
                                AnimatedSize(
                                  duration: M3Motion.spatialFastDuration,
                                  curve: M3Motion.emphasized,
                                  alignment: Alignment.topCenter,
                                  child: _errorMessage == null
                                      ? const SizedBox(width: double.infinity)
                                      : Padding(
                                          padding: const EdgeInsets.only(top: 14),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: scheme.errorContainer,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Row(children: [
                                              Icon(Icons.warning_amber_rounded,
                                                  color: scheme.onErrorContainer,
                                                  size: 18),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(_errorMessage!,
                                                  style: text.bodySmall?.copyWith(
                                                      color: scheme.onErrorContainer))),
                                            ]),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Restore a backup + API key link ──
                      _in(_footerFade, Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          M3PressCard(
                            color: scheme.surfaceContainer,
                            padding: const EdgeInsets.all(16),
                            onTap: _restoring ? null : _restoreFromFile,
                            child: Row(children: [
                              M3CookieBadge(
                                color: scheme.tertiaryContainer,
                                size: 44,
                                child: Icon(Icons.upload_file_rounded,
                                    size: 22,
                                    color: scheme.onTertiaryContainer),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(L.setupRestoreBackup,
                                      style: text.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700)),
                                  Text(L.setupRestoreBackupSub,
                                      style: text.bodySmall?.copyWith(
                                          color: scheme.onSurfaceVariant)),
                                ],
                              )),
                              _restoring
                                  ? SizedBox(width: 20, height: 20,
                                      child: M3Spinner(color: scheme.primary))
                                  : Icon(Icons.chevron_right_rounded,
                                      color: scheme.onSurfaceVariant),
                            ]),
                          ),
                          if (_method == 0) ...[
                            const SizedBox(height: 6),
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
                          ],
                          const SizedBox(height: 12),
                        ],
                      )),
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

// ── Background: two big cookie shapes turning slowly ─────────────────────────
class _SetupBackground extends StatelessWidget {
  final ColorScheme scheme;
  final Size        size;
  final Animation<double> spin; // 0..1, looped slowly
  const _SetupBackground(
      {required this.scheme, required this.size, required this.spin});

  Widget _cookie(double d, Color c, int lobes, Animation<double> turns) =>
      RotationTransition(
        turns: turns,
        child: Container(
          width: d, height: d,
          decoration: ShapeDecoration(
            color: c,
            shape: M3CookieBorder(lobes: lobes, amplitude: 0.08),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(children: [
        Positioned(
          top:   -size.width * 0.30,
          right: -size.width * 0.30,
          child: _cookie(size.width * 0.95,
              scheme.primary.withValues(alpha: 0.08), 7, spin),
        ),
        Positioned(
          bottom: -size.width * 0.35,
          left:   -size.width * 0.35,
          child: _cookie(size.width * 0.90,
              scheme.tertiary.withValues(alpha: 0.07), 5, ReverseAnimation(spin)),
        ),
      ]),
    );
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

// One choice of the connection method list.
class _MethodTile extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _MethodTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return M3PressCard(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(children: [
        M3CookieBadge(
          color: selected ? scheme.primary : scheme.secondaryContainer,
          size: 44,
          child: Icon(icon,
              size: 22,
              color: selected ? scheme.onPrimary : scheme.onSecondaryContainer),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected ? scheme.onPrimaryContainer : null)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: text.bodySmall?.copyWith(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: M3Motion.effectsFastDuration,
          child: Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            key: ValueKey(selected),
            color: selected ? scheme.primary : scheme.outline,
          ),
        ),
      ]),
    );
  }
}
