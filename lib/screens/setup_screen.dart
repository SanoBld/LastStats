import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';
import '../l10n.dart';
import '../services/lastfm_service.dart';
import '../services/data_cache.dart';
import '../services/prefetch_service.dart';
import 'home_screen.dart';

// ══════════════════════════════════════════════════════════════════════════
//  SetupScreen — credentials entry
// ══════════════════════════════════════════════════════════════════════════

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _usernameCtrl  = TextEditingController();
  final _apikeyCtrl    = TextEditingController();
  final _jsonCtrl      = TextEditingController();

  bool    _obscureApiKey = true;
  bool    _rememberMe    = true;
  bool    _isLoading     = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    localeNotifier.addListener(_onLocale);
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_onLocale);
    _usernameCtrl.dispose();
    _apikeyCtrl.dispose();
    _jsonCtrl.dispose();
    super.dispose();
  }

  void _onLocale() => setState(() {});

  Future<void> _setLocale(String code) async {
    localeNotifier.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ls_locale', code);
  }

  // ── Parse JSON inline → remplit les champs ────────────────────────────
  void _applyJson() {
    final raw = _jsonCtrl.text.trim();
    if (raw.isEmpty) return;
    try {
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      final username = (data['username'] ?? '').toString().trim();
      final apiKey   = (data['api_key'] ?? data['apiKey'] ?? data['api-key'] ?? '').toString().trim();
      if (username.isEmpty || apiKey.isEmpty) {
        setState(() => _errorMessage = L.setupInvalidFields);
        return;
      }
      setState(() {
        _usernameCtrl.text = username;
        _apikeyCtrl.text   = apiKey;
        _jsonCtrl.text     = '';
        _errorMessage      = null;
      });
    } catch (_) {
      setState(() => _errorMessage = L.importInvalidJson);
    }
  }

  // ── Validation + connexion ────────────────────────────────────────────
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
    final isEn   = localeNotifier.value == 'en';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Language toggle ───────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LangChip(
                        flag: '🇫🇷', label: 'Français',
                        selected: !isEn,
                        onTap: () => _setLocale('fr'),
                        scheme: scheme, text: text,
                      ),
                      const SizedBox(width: 10),
                      _LangChip(
                        flag: '🇬🇧', label: 'English',
                        selected: isEn,
                        onTap: () => _setLocale('en'),
                        scheme: scheme, text: text,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Logo ──────────────────────────────────────
                  Column(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/icon.png',
                        width: 80, height: 80, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(Icons.headphones_rounded,
                              size: 40, color: scheme.onPrimaryContainer),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('LastStats',
                        style: text.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800, color: scheme.primary)),
                    const SizedBox(height: 4),
                    Text(
                      isEn ? 'Your Last.fm stats, reinvented.'
                           : 'Tes stats Last.fm, réinventées.',
                      style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ]),

                  const SizedBox(height: 40),

                  // ── Card formulaire ───────────────────────────
                  Card(
                    elevation: 0,
                    color: scheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text(
                          isEn ? 'Analyse a profile' : 'Analyser un profil',
                          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 24),

                        // Username
                        TextField(
                          controller:      _usernameCtrl,
                          textInputAction: TextInputAction.next,
                          autocorrect:     false,
                          decoration: InputDecoration(
                            labelText:  isEn ? 'Last.fm username' : 'Pseudo Last.fm',
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // API key
                        TextField(
                          controller:        _apikeyCtrl,
                          textInputAction:   TextInputAction.done,
                          obscureText:       _obscureApiKey,
                          autocorrect:       false,
                          enableSuggestions: false,
                          onSubmitted:       (_) => _launch(),
                          decoration: InputDecoration(
                            labelText: isEn ? 'Last.fm API key' : 'Clé API Last.fm',
                            hintText:  isEn ? '32-character hex key' : 'Clé hexadécimale de 32 caractères',
                            prefixIcon: const Icon(Icons.key_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureApiKey
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () =>
                                  setState(() => _obscureApiKey = !_obscureApiKey),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Hint sécurité
                        Row(children: [
                          Icon(Icons.shield_outlined, size: 14, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(child: Text(
                            isEn ? 'Stored locally. Never sent to a third party.'
                                 : 'Stockée localement. Jamais envoyée à un tiers.',
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          )),
                        ]),
                        const SizedBox(height: 16),

                        // Remember me
                        Row(children: [
                          Checkbox(
                            value:     _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v ?? true),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _rememberMe = !_rememberMe),
                            child: Text(isEn ? 'Remember me' : 'Se souvenir de moi'),
                          ),
                        ]),
                        const SizedBox(height: 20),

                        // Bouton lancer
                        FilledButton.icon(
                          onPressed: _isLoading ? null : _launch,
                          icon: _isLoading
                              ? SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: scheme.onPrimary))
                              : const Icon(Icons.bar_chart_rounded),
                          label: Text(_isLoading
                              ? (isEn ? 'Connecting…' : 'Connexion…')
                              : (isEn ? 'Start analysis' : "Lancer l'analyse")),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),

                        // Bloc erreur
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.errorContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: scheme.onErrorContainer, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_errorMessage!,
                                  style: text.bodySmall
                                      ?.copyWith(color: scheme.onErrorContainer))),
                            ]),
                          ),
                        ],
                      ]),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Séparateur "ou" ───────────────────────────
                  Row(children: [
                    Expanded(child: Divider(color: scheme.outlineVariant)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(isEn ? 'or' : 'ou',
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ),
                    Expanded(child: Divider(color: scheme.outlineVariant)),
                  ]),

                  const SizedBox(height: 16),

                  // ── Card import JSON ──────────────────────────
                  Card(
                    elevation: 0,
                    color: scheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(children: [
                          Icon(Icons.upload_file_rounded, size: 20, color: scheme.primary),
                          const SizedBox(width: 8),
                          Text(L.setupImportJson,
                              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 8),
                        Text(L.setupImportHintLabel,
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text(L.setupImportNote,
                            style: text.bodySmall?.copyWith(
                                fontFamily: 'monospace', color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 12),

                        TextField(
                          controller:  _jsonCtrl,
                          maxLines:    4,
                          minLines:    3,
                          autocorrect: false,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          decoration: InputDecoration(
                            hintText: L.setupImportFormat,
                            hintStyle: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          onPressed: _applyJson,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(L.importRestore),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Lien API Last.fm ──────────────────────────
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse('https://www.last.fm/api/account/create');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon:  const Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text(isEn
                          ? 'Get a free API key'
                          : 'Obtenir une clé API gratuitement'),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Language chip ─────────────────────────────────────────────────────────────

class _LangChip extends StatelessWidget {
  final String flag, label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final TextTheme text;

  const _LangChip({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scheme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? scheme.primary.withValues(alpha: 0.6)
              : scheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 7),
            Text(
              label,
              style: text.labelMedium?.copyWith(
                color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  _FirstLoadScreen — shown once on first connection to prefetch all data
// ══════════════════════════════════════════════════════════════════════════

class _FirstLoadScreen extends StatefulWidget {
  final String username;
  final String apiKey;
  final LastFmService service;
  final int totalScrobbles;

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

  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulse;
  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fade;

  static List<(String, String)> get _steps => localeNotifier.value == 'en'
      ? [
          ('🎵', 'Loading your profile…'),
          ('📊', 'Fetching your top artists…'),
          ('💿', 'Fetching your top albums…'),
          ('🎶', 'Fetching your top tracks…'),
          ('🕐', 'Analysing recent plays…'),
          ('📅', 'Building your music calendar…'),
          ('🏆', 'Computing rankings…'),
          ('✨', 'Finishing up…'),
        ]
      : [
          ('🎵', 'Chargement de ton profil…'),
          ('📊', 'Récupération de tes top artistes…'),
          ('💿', 'Récupération de tes top albums…'),
          ('🎶', 'Récupération de tes top tracks…'),
          ('🕐', 'Analyse des écoutes récentes…'),
          ('📅', 'Construction du calendrier musical…'),
          ('🏆', 'Calcul des classements…'),
          ('✨', 'Finalisation…'),
        ];

  int    _stepIndex   = 0;
  double _progress    = 0.0;
  bool   _done        = false;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _startPrefetch();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _startPrefetch() async {
    final steps = _steps;
    final stepDuration = Duration(milliseconds: 650);

    // Real prefetch runs concurrently
    final prefetchFuture = _runPrefetch();

    for (var i = 0; i < steps.length; i++) {
      if (!mounted) return;
      setState(() {
        _stepIndex = i;
        _progress  = (i + 1) / steps.length;
      });
      await Future.delayed(stepDuration);
    }

    await prefetchFuture;

    if (!mounted) return;
    setState(() { _done = true; _progress = 1.0; });

    // Brief pause to show "done" state, then fade+slide to HomeScreen
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => HomeScreen(
          username: widget.username,
          apiKey:   widget.apiKey,
        ),
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
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
  }

  Future<void> _runPrefetch() async {
    try {
      await DataCache.init();
      await PrefetchService.prefetchAll(widget.service, force: true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final steps  = _steps;
    final step   = steps[_stepIndex.clamp(0, steps.length - 1)];
    final isEn   = localeNotifier.value == 'en';

    return Scaffold(
      backgroundColor: scheme.surface,
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // ── Pulsing icon ──────────────────────────────────────────
                ScaleTransition(
                  scale: _pulse,
                  child: Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color:  scheme.primary.withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(Icons.headphones_rounded,
                        size: 48, color: scheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(height: 36),

                // ── Title ─────────────────────────────────────────────────
                Text('LastStats',
                    style: text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800, color: scheme.primary)),
                const SizedBox(height: 8),
                Text(
                  isEn ? 'Welcome, ${widget.username}!'
                       : 'Bienvenue, ${widget.username}\u00a0!',
                  style: text.titleMedium?.copyWith(color: scheme.onSurface),
                ),
                if (widget.totalScrobbles > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    isEn
                        ? '${_fmtLarge(widget.totalScrobbles)} scrobbles to analyse'
                        : '${_fmtLarge(widget.totalScrobbles)} scrobbles à analyser',
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 48),

                // ── Progress bar ──────────────────────────────────────────
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _progress),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Current step ──────────────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end:   Offset.zero,
                      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                      child: child,
                    ),
                  ),
                  child: Row(
                    key: ValueKey(_done ? 'done' : _stepIndex),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_done ? '✅' : step.$1,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _done
                              ? (isEn ? 'All set!' : 'Tout est prêt\u00a0!')
                              : step.$2,
                          style: text.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // ── Tip ───────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        size: 16, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      isEn
                          ? 'One-time load — your data will be cached for an instant experience next time.'
                          : 'Chargement unique — tes données seront mises en cache pour une expérience instantanée.',
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    )),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _fmtLarge(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}