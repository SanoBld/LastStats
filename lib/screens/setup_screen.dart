import '../theme/m3_interaction.dart';
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
import 'dart:convert';
import '../services/api_http.dart';
import '../services/data_source.dart';
import '../services/source_switch.dart';
import '../services/account_manager.dart';
import '../services/lb_auth.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

// ══════════════════════════════════════════════════════════════════════════
//  SetupScreen — credentials entry (animated redesign)
// ══════════════════════════════════════════════════════════════════════════

/// Picks the self-contained logo SVG (own background baked in) matching the
/// current brightness.
String _logoAsset(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return 'assets/icons/app_logo_${dark ? 'black_bg' : 'white_bg'}.svg';
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {

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
  // Service choice: null = choice screen, 'lfm' = Last.fm form, 'lb' = ListenBrainz form
  String? _service;
  final _lbTokenCtrl = TextEditingController();
  bool _lbObscure = true;
  String? _lbInfo;
  String _clipToken = '';      // a token found in the clipboard
  bool _lbShowOptions = false; // display-name field

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
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    localeNotifier.removeListener(_onLocale);
    _usernameCtrl.dispose();
    _lbTokenCtrl.dispose();
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
    if (!result.success) {
      setState(() => _errorMessage = L.importInvalidFormat);
      return;
    }
    // A ListenBrainz backup: fill the token and connect, never the Last.fm form.
    if (result.isListenBrainz) {
      final tok = result.apiKey ?? '';
      if (!LbAuth.looksLikeToken(tok)) {
        setState(() { _service = 'lb'; _errorMessage = tx('lbl_restore_bad'); });
        return;
      }
      setState(() {
        _service = 'lb';
        _lbTokenCtrl.text = LbAuth.clean(tok);
        _errorMessage = null;
      });
      await _lbConnect();
      return;
    }
    if ((result.username ?? '').isEmpty || (result.apiKey ?? '').isEmpty) {
      setState(() => _errorMessage = tx('lbl_restore_bad'));
      return;
    }
    setState(() {
      _service           = 'lfm';
      _usernameCtrl.text = result.username!;
      _apikeyCtrl.text   = result.apiKey!;
      _useInternalKey    = false;
      _method            = 0;
      _errorMessage      = null;
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

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── ListenBrainz login ─────────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the ListenBrainz website: offer the token that was copied.
    if (state == AppLifecycleState.resumed && _service == 'lb') _checkClipboard();
  }

  Future<void> _checkClipboard() async {
    try {
      final d = await Clipboard.getData(Clipboard.kTextPlain);
      final t = d?.text ?? '';
      if (!mounted) return;
      if (t.isEmpty || t.length > 400 || !LbAuth.looksLikeToken(t)) {
        if (_clipToken.isNotEmpty) setState(() => _clipToken = '');
        return;
      }
      final tok = LbAuth.clean(t);
      if (tok == LbAuth.clean(_lbTokenCtrl.text)) return;
      setState(() => _clipToken = tok);
    } catch (_) {}
  }

  Future<void> _pasteToken() async {
    try {
      final d = await Clipboard.getData(Clipboard.kTextPlain);
      final t = d?.text ?? '';
      if (t.trim().isEmpty) return;
      setState(() { _lbTokenCtrl.text = LbAuth.clean(t); _errorMessage = null; _clipToken = ''; });
      if (LbAuth.looksLikeToken(t)) await _lbConnect();
    } catch (_) {}
  }

  String _lbError(LbAuthResult r) {
    final m = switch (r.status) {
      LbAuthStatus.empty       => tx('lb_empty'),
      LbAuthStatus.badFormat   => tx('lbl_err_format'),
      LbAuthStatus.invalid     => tx('lbl_err_invalid'),
      LbAuthStatus.rateLimited => tx('lbl_err_rate'),
      LbAuthStatus.server      => tx('lbl_err_server'),
      LbAuthStatus.network     => tx('lbl_err_net'),
      LbAuthStatus.ok          => '',
    };
    return r.detail.isEmpty ? m : '$m\n${r.detail}';
  }

  Future<void> _lbConnect() async {
    if (_isLoading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() { _isLoading = true; _errorMessage = null; _clipToken = ''; });
    try {
      final r = await LbAuth.validate(_lbTokenCtrl.text);
      if (!mounted) return;
      if (!r.ok) {
        setState(() => _errorMessage = _lbError(r));
        return;
      }
      // An error after the check is NOT a network error: show it as is.
      try {
        final prefs = await SharedPreferences.getInstance();
        final fromLb = DataSource.lb;
        await LbAuth.save(r.userName, r.token);
        final customName = _displayNameCtrl.text.trim();
        if (customName.isNotEmpty) {
          displayNameNotifier.value = customName;
          await prefs.setString('ls_display_name', customName);
        }
        if (!mounted) return;
        await SourceSwitch.handle(context,
            fromLb: fromLb, toLb: true, username: r.userName, apiKey: r.token);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          M3FadeThroughRoute<void>(
            builder: (_) => OnboardingFlow(username: r.userName, apiKey: r.token),
          ),
        );
      } catch (e) {
        if (mounted) {
          setState(() => _errorMessage = tx('lbl_err_after',
              {'e': e.toString().replaceFirst('Exception: ', '')}));
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _errorBox(ColorScheme scheme, TextTheme text) => AnimatedSize(
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
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.warning_amber_rounded,
                        color: scheme.onErrorContainer, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!,
                        style: text.bodySmall?.copyWith(color: scheme.onErrorContainer))),
                  ]),
                ),
              ),
      );

  // First screen: two clear choices, the free one first.
  List<Widget> _choiceWidgets(ColorScheme scheme, TextTheme text) => [
    Text(tx('svc_title'),
        style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
    const SizedBox(height: 4),
    Text(tx('svc_sub'),
        style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
    const SizedBox(height: 18),
    _ServiceTile(
      icon: Icons.favorite_rounded,
      title: 'ListenBrainz',
      badge: '${tx('svc_recommended')} · ${tx('svc_free')}',
      warn: false,
      subtitle: tx('svc_lb_s'),
      onTap: () => setState(() { _service = 'lb'; _errorMessage = null; _checkClipboard(); }),
    ),
    const SizedBox(height: 10),
    _ServiceTile(
      icon: Icons.graphic_eq_rounded,
      title: 'Last.fm',
      badge: tx('svc_lfm_paid'),
      warn: true,
      subtitle: tx('svc_lfm_s'),
      onTap: () => setState(() { _service = 'lfm'; _errorMessage = null; }),
    ),
    const SizedBox(height: 6),
    Wrap(alignment: WrapAlignment.center, spacing: 4, children: [
      M3LabelButton(
        kind: M3ButtonKind.text, height: 44, icon: Icons.open_in_new_rounded,
        label: tx('lb_create'),
        onTap: () => _open('https://listenbrainz.org/login/musicbrainz/?login_hint=register'),
      ),
      M3LabelButton(
        kind: M3ButtonKind.text, height: 44, icon: Icons.open_in_new_rounded,
        label: tx('lfm_create'),
        onTap: () => _open('https://www.last.fm/join'),
      ),
    ]),
  ];

  Widget _backButton() => Align(
    alignment: Alignment.centerLeft,
    child: M3LabelButton(
      kind: M3ButtonKind.text, height: 44, icon: Icons.arrow_back_rounded,
      label: tx('svc_back'),
      onTap: () => setState(() {
        _service = null; _errorMessage = null; _lbInfo = null; _clipToken = '';
      }),
    ),
  );

  List<Widget> _lfmIntro(ColorScheme scheme, TextTheme text) => [
    _backButton(),
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline_rounded, size: 20, color: scheme.onErrorContainer),
        const SizedBox(width: 10),
        Expanded(child: Text(tx('svc_lfm_note'),
            style: text.bodySmall?.copyWith(color: scheme.onErrorContainer))),
      ]),
    ),
    const SizedBox(height: 14),
  ];

  // ListenBrainz: open the page -> paste -> connect.
  List<Widget> _lbWidgets(ColorScheme scheme, TextTheme text) {
    final raw = _lbTokenCtrl.text;
    final typed = raw.trim().isNotEmpty;
    final fmtOk = LbAuth.looksLikeToken(raw);
    return [
      _backButton(),
      Text(tx('lb_title'),
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 14),
      _StepBlock(
        n: 1, title: tx('lbl_step1_t'), subtitle: tx('lbl_step1_s'),
        done: typed,
        child: M3LabelButton(
          kind: M3ButtonKind.tonal, expand: true,
          icon: Icons.open_in_new_rounded,
          label: tx('lbl_open'),
          onTap: () => _open('https://listenbrainz.org/settings/'),
        ),
      ),
      const SizedBox(height: 12),
      _StepBlock(
        n: 2, title: tx('lbl_step2_t'), subtitle: '',
        done: fmtOk,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AnimatedSize(
            duration: M3Motion.spatialFastDuration,
            curve: M3Motion.emphasized,
            alignment: Alignment.topCenter,
            child: _clipToken.isEmpty
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        Icon(Icons.content_paste_go_rounded,
                            size: 20, color: scheme.onPrimaryContainer),
                        const SizedBox(width: 10),
                        Expanded(child: Text(tx('lbl_detected'),
                            style: text.bodySmall?.copyWith(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600))),
                        FilledButton(
                          onPressed: _isLoading ? null : () {
                            setState(() {
                              _lbTokenCtrl.text = _clipToken;
                              _clipToken = '';
                            });
                            _lbConnect();
                          },
                          child: Text(tx('lbl_use')),
                        ),
                      ]),
                    ),
                  ),
          ),
          TextField(
            controller: _lbTokenCtrl,
            obscureText: _lbObscure,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.go,
            onChanged: (_) => setState(() { _errorMessage = null; }),
            onSubmitted: (_) => _lbConnect(),
            decoration: _dec(scheme, tx('lb_token'), Icons.key_rounded,
                suffix: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: Icon(_lbObscure
                        ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _lbObscure = !_lbObscure),
                  ),
                  IconButton(
                    tooltip: tx('lbl_paste'),
                    icon: const Icon(Icons.content_paste_rounded),
                    onPressed: _isLoading ? null : _pasteToken,
                  ),
                ])),
          ),
          AnimatedSize(
            duration: M3Motion.spatialFastDuration,
            curve: M3Motion.emphasized,
            alignment: Alignment.topCenter,
            child: !typed
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Row(children: [
                      Icon(fmtOk ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          size: 16,
                          color: fmtOk ? scheme.primary : scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(child: Text(
                          fmtOk ? tx('lbl_format_ok') : tx('lbl_format_bad'),
                          style: text.bodySmall?.copyWith(
                              color: fmtOk ? scheme.primary : scheme.onSurfaceVariant))),
                    ]),
                  ),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      M3LabelButton(
        kind: M3ButtonKind.filled, expand: true, loading: _isLoading,
        icon: Icons.arrow_forward_rounded,
        label: _isLoading ? L.setupConnecting : tx('lb_connect'),
        onTap: _lbConnect,
      ),
      _errorBox(scheme, text),
      const SizedBox(height: 6),
      Align(
        alignment: Alignment.centerLeft,
        child: M3LabelButton(
          kind: M3ButtonKind.text, height: 44,
          icon: _lbShowOptions ? Icons.expand_less_rounded : Icons.tune_rounded,
          label: tx('lbl_options'),
          onTap: () => setState(() => _lbShowOptions = !_lbShowOptions),
        ),
      ),
      AnimatedSize(
        duration: M3Motion.spatialFastDuration,
        curve: M3Motion.emphasized,
        alignment: Alignment.topCenter,
        child: !_lbShowOptions
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 6),
                child: TextField(
                  controller: _displayNameCtrl,
                  textInputAction: TextInputAction.done,
                  decoration: _dec(scheme, L.settingsDisplayNameLabel,
                      Icons.badge_outlined, hint: L.settingsDisplayNameHint),
                ),
              ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.shield_outlined, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(child: Text(tx('lbl_why'),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
        ]),
      ),
    ];
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

      final fromLb = DataSource.lb;
      await DataSource.set(listenbrainz: false); // Last.fm mode
      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ls_username', username);
        await prefs.setString('ls_apikey',   apiKey);
        // Coming back from ListenBrainz: drop its account from the list
        if (fromLb) await AccountManager.setSingle(AccountEntry(username: username, apiKey: apiKey));
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
      await SourceSwitch.handle(context, fromLb: fromLb, toLb: false, username: username, apiKey: apiKey);
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
      if (mounted) setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
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
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.black : const Color(0xFFF5F5F5),
                                      shape: const M3CookieBorder(
                                          lobes: 9, amplitude: 0.07),
                                    ),
                                  ),
                                ),
                                // Logo stays still, only the star turns
                                SvgPicture.asset(
                                    'assets/icons/app_logo_${Theme.of(context).brightness == Brightness.dark ? 'white' : 'black'}.svg',
                                    width: 140, height: 140),
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
                            child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), switchInCurve: Curves.easeOutCubic, switchOutCurve: Curves.easeInCubic, layoutBuilder: (cur, prev) => Stack(alignment: Alignment.topCenter, children: [...prev, if (cur != null) cur]), transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(a), child: c)), child: Column(key: ValueKey<String>(_service ?? 'choice'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_service == null) ..._choiceWidgets(scheme, text)
                                else if (_service == 'lb') ..._lbWidgets(scheme, text)
                                else ...[
                                  ..._lfmIntro(scheme, text),
                                Text(tx('wl_title'),
                                    style: text.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(tx('wl_sub'),
                                    style: text.bodyMedium?.copyWith(
                                        color: scheme.onSurfaceVariant)),
                                const SizedBox(height: 18),

                                // Connection method: one compact selector
                                SegmentedButton<int>(
                                  showSelectedIcon: false,
                                  segments: [
                                    ButtonSegment(value: 0,
                                        icon: const Icon(Icons.key_rounded, size: 18),
                                        label: Text(tx('lfm_seg_key'))),
                                    ButtonSegment(value: 1,
                                        icon: const Icon(Icons.bolt_rounded, size: 18),
                                        label: Text(tx('lfm_seg_builtin'))),
                                    if (_canWebLogin)
                                      ButtonSegment(value: 2,
                                          icon: const Icon(Icons.login_rounded, size: 18),
                                          label: Text(tx('lfm_seg_web'))),
                                  ],
                                  selected: {_method},
                                  onSelectionChanged: (v) => setState(() {
                                    _method = v.first;
                                    _useInternalKey = v.first != 0;
                                  }),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  switch (_method) {
                                    0 => tx('sm_key_s'),
                                    1 => tx('sm_builtin_s'),
                                    _ => tx('lfm_web_sub'),
                                  },
                                  style: text.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant),
                                ),
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
                                M3LabelButton(
                                  kind: M3ButtonKind.filled,
                                  expand: true,
                                  loading: _isLoading,
                                  icon: _method == 2 ? Icons.login_rounded : Icons.arrow_forward_rounded,
                                  label: _isLoading
                                      ? L.setupConnecting
                                      : (_method == 2 ? tx('conn_lfm_web') : tx('conn_connect')),
                                  onTap: _method == 2 ? _lastfmWeb : _launch,
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
                                ]
                              ],
                            )),
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
                          if (_service == 'lfm' && _method == 0) ...[
                            const SizedBox(height: 6),
                            Center(
                              child: M3LabelButton(
                                kind: M3ButtonKind.text,
                                height: 44,
                                icon: Icons.open_in_new_rounded,
                                label: L.setupGetApiKey,
                                onTap: () async {
                                  final uri = Uri.parse('https://www.last.fm/api/account/create');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
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
      child: M3InkWell(
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

// ── Service choice tile (Last.fm / ListenBrainz) ──────────────────────
class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, badge;
  final bool warn; // true = warning color (paid), false = free
  final VoidCallback onTap;
  const _ServiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.warn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return M3PressCard(
      color: scheme.surfaceContainerHigh,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(children: [
        M3CookieBadge(
          color: scheme.secondaryContainer,
          size: 48,
          child: Icon(icon, size: 24, color: scheme.onSecondaryContainer),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: warn ? scheme.errorContainer : scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge,
                    style: text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: warn ? scheme.onErrorContainer : scheme.onPrimaryContainer)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(subtitle,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
      ]),
    );
  }
}

// ── One numbered step of the ListenBrainz login ───────────────────────────
class _StepBlock extends StatelessWidget {
  final int n;
  final String title, subtitle;
  final bool done;
  final Widget child;
  const _StepBlock({
    required this.n,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 28, height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? scheme.primary : scheme.secondaryContainer,
            ),
            child: done
                ? Icon(Icons.check_rounded, size: 18, color: scheme.onPrimary)
                : Text('$n', style: text.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSecondaryContainer)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
        ]),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(subtitle,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}
