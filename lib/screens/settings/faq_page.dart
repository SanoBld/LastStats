// lib/screens/settings/faq_page.dart

import 'package:flutter/material.dart';
import '../../l10n.dart';
import '../../app_state.dart';
import 'settings_helpers.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  @override
  void initState() {
    super.initState();
    localeNotifier.addListener(_rebuild);
  }

  @override
  void dispose() { localeNotifier.removeListener(_rebuild); super.dispose(); }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final isEn   = localeNotifier.value == 'en';

    final items = isEn ? _itemsEn : _itemsFr;

    return Scaffold(
      appBar: AppBar(
        title: Text(L.settingsFaq),
        centerTitle: false,
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        // ── Questions / réponses ──────────────────────────────────────────
        SettingsSection(
          label: L.faqSectionLabel,
          children: [
            ...items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(children: [
                _FaqTile(item: e.value),
                if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
              ]);
            }),
          ],
        ),

        const SizedBox(height: 16),

        // ── Badge open source ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(children: [
            Icon(Icons.favorite_rounded, size: 16, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(
              L.faqOpenSourceBadge,
              style: text.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
            )),
          ]),
        ),

        const SizedBox(height: 20),
      ]),
    );
  }
}

// ── Modèle ────────────────────────────────────────────────────────────────────

class _FaqItem {
  final IconData icon;
  final String question;
  final String answer;
  const _FaqItem(this.icon, this.question, this.answer);
}

// ── Contenu FR ────────────────────────────────────────────────────────────────

const _itemsFr = [
  _FaqItem(
    Icons.sync_rounded,
    'Est-ce que LastStats scrobble ma musique ?',
    'Non. LastStats est une application de visualisation : elle affiche les scrobbles '
    'déjà enregistrés sur ton compte Last.fm, mais elle n\'en enregistre pas elle-même.\n\n'
    'Pour scrobbler automatiquement ta musique, utilise une application dédiée comme '
    'Pano Scrobbler (disponible sur Android).',
  ),
  _FaqItem(
    Icons.phone_iphone_rounded,
    'Une version iOS est-elle prévue ?',
    'Non. Une version iOS n\'est pas prévue pour le moment.',
  ),
  _FaqItem(
    Icons.devices_other_rounded,
    'L\'app fonctionne-t-elle sur macOS ou d\'autres plateformes ?',
    'LastStats Mobile est développé et testé sur Android. '
    'Le fonctionnement sur d\'autres plateformes (macOS, Windows, Linux…) n\'est pas vérifié — '
    'des bugs ou des dysfonctionnements sont possibles.',
  ),
  _FaqItem(
    Icons.code_rounded,
    'LastStats est-il open source ?',
    'Oui ! Le code source est disponible librement sur GitHub. '
    'Le projet est indépendant, réalisé avec passion par SanoBld. '
    'Tu peux y contribuer, signaler des bugs ou simplement laisser une étoile ⭐.',
  ),
];

// ── Contenu EN ────────────────────────────────────────────────────────────────

const _itemsEn = [
  _FaqItem(
    Icons.sync_rounded,
    'Does LastStats scrobble my music?',
    'No. LastStats is a visualisation app: it displays the scrobbles already recorded '
    'on your Last.fm account, but it does not record any itself.\n\n'
    'To automatically scrobble your music, use a dedicated app such as '
    'Pano Scrobbler (available on Android).',
  ),
  _FaqItem(
    Icons.phone_iphone_rounded,
    'Is an iOS version planned?',
    'No. An iOS version is not planned at this time.',
  ),
  _FaqItem(
    Icons.devices_other_rounded,
    'Does the app work on macOS or other platforms?',
    'LastStats Mobile is developed and tested on Android. '
    'Behaviour on other platforms (macOS, Windows, Linux…) is unverified — '
    'bugs or unexpected behaviour may occur.',
  ),
  _FaqItem(
    Icons.code_rounded,
    'Is LastStats open source?',
    'Yes! The source code is freely available on GitHub. '
    'The project is independent, built with passion by SanoBld. '
    'Feel free to contribute, report bugs, or leave a star ⭐.',
  ),
];

// ── Tuile FAQ expansible ──────────────────────────────────────────────────────

class _FaqTile extends StatefulWidget {
  final _FaqItem item;
  const _FaqTile({super.key, required this.item});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(widget.item.icon, size: 18, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(widget.item.question,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: scheme.onSurfaceVariant),
            ),
          ]),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10, left: 30),
              child: Text(widget.item.answer,
                  style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant, height: 1.55)),
            ),
          ),
        ]),
      ),
    );
  }
}