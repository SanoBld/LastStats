// lib/screens/settings/faq_page.dart

import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
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

    final items = [
      _FaqItem(Icons.sync_rounded,          L.faqQ1, L.faqA1),
      _FaqItem(Icons.phone_iphone_rounded,  L.faqQ2, L.faqA2),
      _FaqItem(Icons.devices_other_rounded, L.faqQ3, L.faqA3),
      _FaqItem(Icons.code_rounded,          L.faqQ4, L.faqA4),
      _FaqItem(Icons.lock_outline_rounded,  L.faqQ5, L.faqA5),
      _FaqItem(Icons.favorite_border_rounded, L.faqQ6, L.faqA6),
    ];

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