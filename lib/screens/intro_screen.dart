// lib/screens/intro_screen.dart
// First-launch walkthrough: welcome (+ language), privacy, models, ready.
// Same visual language as the LastStats onboarding (cookie badge header,
// fade + slide-up reveal, progress bar on top).

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/l10n.dart';
import '../models/model_models.dart';
import '../services/hf_service.dart';
import '../services/memory_store.dart';
import '../services/model_manager.dart';
import '../services/prefs.dart';
import '../supported_locales.dart';
import '../theme/m3_motion.dart';
import '../widgets/brand_icon.dart';
import '../widgets/m3_components.dart';
import 'home_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  static const _pages = 5;
  final _name = TextEditingController();
  final _work = TextEditingController();
  final _likes = TextEditingController();
  final _aiStyle = TextEditingController();

  @override
  void initState() {
    super.initState();
    localeNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_rebuild);
    _pageCtrl.dispose();
    for (final c in [_name, _work, _likes, _aiStyle]) {
      c.dispose();
    }
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _goTo(int i) {
    setState(() => _page = i);
    _pageCtrl.animateToPage(i,
        duration: const Duration(milliseconds: 320), curve: M3Motion.emphasizedDecelerate);
  }

  Future<void> _finish() async {
    final name = _name.text.trim();
    if (name.isNotEmpty) {
      displayNameNotifier.value = name;
      await savePref('pc_display_name', name);
      await MemoryStore.instance.add('Name: $name');
    }
    if (_work.text.trim().isNotEmpty) await MemoryStore.instance.add('Work/studies: ${_work.text.trim()}');
    if (_likes.text.trim().isNotEmpty) await MemoryStore.instance.add('Interests: ${_likes.text.trim()}');
    if (_aiStyle.text.trim().isNotEmpty) {
      systemPromptNotifier.value = _aiStyle.text.trim();
      await savePref('pc_system_prompt', _aiStyle.text.trim());
    }
    await savePref('pc_onboarded', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      M3FadeThroughRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final last = _page == _pages - 1;

    // System back goes to the previous step instead of closing the app.
    return PopScope(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(_page - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: M3WavyProgress(
                value: (_page + 1) / _pages,
                height: 12,
                stroke: 4,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 4),
              child: Row(children: [
                Text('${_page + 1}/$_pages',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (!last) M3LabelButton(kind: M3ButtonKind.text, height: 40, label: tr('intro_skip'), onTap: _finish),
              ]),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  const _WelcomeStep(),
                  const _PrivacyStep(),
                  _AboutStep(name: _name, work: _work, likes: _likes, aiStyle: _aiStyle),
                  const _ModelStep(),
                  const _ReadyStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(children: [
                if (_page > 0)
                  M3LabelButton(kind: M3ButtonKind.tonal, icon: Icons.arrow_back_rounded, label: tr('intro_back'), onTap: () => _goTo(_page - 1)),
                const Spacer(),
                M3LabelButton(
                  kind: M3ButtonKind.filled,
                  icon: last ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  label: last ? tr('intro_start') : tr('intro_next'),
                  onTap: () => last ? _finish() : _goTo(_page + 1),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Shared step layout ───────────────────────────────────────────────────────

class _Step extends StatelessWidget {
  final IconData? icon;
  final Widget? badge;
  final String title, subtitle;
  final Widget? child;
  const _Step({this.icon, this.badge, required this.title, required this.subtitle, this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), children: [
          _Reveal(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(28)),
              child: Row(children: [
                M3CookieBadge(
                  size: 56,
                  color: scheme.primary,
                  child: badge ?? Icon(icon, color: scheme.onPrimary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: text.bodyMedium?.copyWith(color: scheme.onPrimaryContainer.withValues(alpha: 0.8))),
                  ]),
                ),
              ]),
            ),
          ),
          if (child != null) ...[
            const SizedBox(height: 20),
            _Reveal(delay: 90, child: child!),
          ],
        ]),
      ),
    );
  }
}

/// Fade + slide-up entrance.
class _Reveal extends StatelessWidget {
  final Widget child;
  final int delay;
  const _Reveal({required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 420 + delay),
        curve: M3Motion.emphasizedDecelerate,
        builder: (_, v, c) => Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: c),
        ),
        child: child,
      );
}

class _Point extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _Point(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Steps ────────────────────────────────────────────────────────────────────

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: localeNotifier,
      builder: (_, _) => _Step(
        badge: BrandIcon('assets/icons/app_logo.svg', Icons.chat_bubble_rounded, size: 30, color: scheme.onPrimary),
        title: tr('intro1_t'),
        subtitle: tr('intro1_s'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('set_language'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final l in kSupportedLocales)
              M3Chip(
                label: Text('${l.flag} ${l.nativeName}'),
                selected: localeNotifier.value == l.code,
                onSelected: (_) {
                  localeNotifier.value = l.code;
                  savePref('pc_locale', l.code);
                },
              ),
          ]),
        ]),
      ),
    );
  }
}

class _PrivacyStep extends StatelessWidget {
  const _PrivacyStep();

  @override
  Widget build(BuildContext context) => _Step(
        icon: Icons.lock_rounded,
        title: tr('intro2_t'),
        subtitle: tr('intro2_s'),
        child: Column(children: [
          _Point(Icons.phone_android_rounded, tr('pv_1_t'), tr('pv_1_s')),
          _Point(Icons.cloud_off_rounded, tr('pv_2_t'), tr('pv_2_s')),
          _Point(Icons.person_off_rounded, tr('pv_4_t'), tr('pv_4_s')),
        ]),
      );
}

class _ModelStep extends StatefulWidget {
  const _ModelStep();

  @override
  State<_ModelStep> createState() => _ModelStepState();
}

class _ModelStepState extends State<_ModelStep> {
  static final RecommendedModel _rec = kRecommendedModels.first;
  String? _error;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    ModelManager.instance.addListener(_rebuild);
  }

  @override
  void dispose() {
    ModelManager.instance.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      await ModelManager.instance.downloadRecommended(_rec.repo);
    } on HfException catch (e) {
      _error = tr('err_${e.kind}');
    }
    if (mounted) setState(() => _starting = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final mgr = ModelManager.instance;
    final installed = mgr.installed.any((m) => m.repo == _rec.repo);
    final tasks = mgr.tasks.where((t) => t.repo == _rec.repo).toList();
    final task = tasks.isEmpty ? null : tasks.first;

    Widget action;
    if (installed) {
      action = Row(children: [
        Icon(Icons.check_circle_rounded, color: scheme.primary),
        const SizedBox(width: 10),
        Text(tr('intro3_done'), style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
      ]);
    } else if (task != null && task.status != DownloadStatus.failed) {
      action = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        task.total > 0
            ? M3WavyProgress(value: task.fraction, height: 14)
            : const M3WavyProgress(indeterminate: true, height: 14),
        const SizedBox(height: 8),
        Text('${formatBytes(task.received)}${task.total > 0 ? ' / ${formatBytes(task.total)}' : ''}',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      ]);
    } else {
      action = M3LabelButton(
        kind: M3ButtonKind.filled,
        icon: Icons.download_rounded,
        label: tr('intro3_download'),
        loading: _starting,
        onTap: _start,
      );
    }

    return _Step(
      icon: Icons.memory_rounded,
      title: tr('intro3_t'),
      subtitle: tr('intro3_s'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Material(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_rec.title} · ${_rec.params}', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('${tr(_rec.blurbKey)} · ~${formatBytes(_rec.approxMb * 1024 * 1024)}',
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              action,
              if (_error != null || task?.status == DownloadStatus.failed) ...[
                const SizedBox(height: 8),
                Text(_error ?? tr('err_${task?.errorKind ?? 'server'}'), style: text.bodySmall?.copyWith(color: scheme.error)),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Text(tr('intro3_later'), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      ]),
    );
  }
}

class _ReadyStep extends StatelessWidget {
  const _ReadyStep();

  @override
  Widget build(BuildContext context) => _Step(
        icon: Icons.rocket_launch_rounded,
        title: tr('intro4_t'),
        subtitle: tr('intro4_s'),
        child: Column(children: [
          _Point(Icons.chat_bubble_outline_rounded, tr('intro4_a_t'), tr('intro4_a_s')),
          _Point(Icons.tune_rounded, tr('intro4_b_t'), tr('intro4_b_s')),
        ]),
      );
}


class _AboutStep extends StatelessWidget {
  final TextEditingController name, work, likes, aiStyle;
  const _AboutStep({required this.name, required this.work, required this.likes, required this.aiStyle});

  Widget _f(TextEditingController c, String q) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(labelText: q, border: const OutlineInputBorder()),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('onb_title'), style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(tr('onb_sub'), style: text.bodyMedium),
            const SizedBox(height: 20),
            _f(name, tr('onb_q_name')),
            _f(work, tr('onb_q_work')),
            _f(likes, tr('onb_q_likes')),
            _f(aiStyle, tr('onb_q_ai')),
          ]),
        ),
      ),
    );
  }
}
