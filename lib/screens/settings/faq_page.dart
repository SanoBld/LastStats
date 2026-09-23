// lib/screens/settings/faq_page.dart

import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../app_state.dart';
import 'settings_helpers.dart';
import 'settings_rows.dart';

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
      _FaqItem(Icons.repeat_rounded,          L.faqQ7, L.faqA7),
      _FaqItem(Icons.military_tech_rounded,   L.faqQ8, L.faqA8),
      _FaqItem(Icons.battery_saver_rounded,   L.faqQ9, L.faqA9),
      _FaqItem(Icons.backup_rounded,          L.faqQ10, L.faqA10),
      _FaqItem(Icons.wifi_off_rounded,        L.faqQ11, L.faqA11),
      _FaqItem(Icons.swap_horiz_rounded,      L.faqQ12, L.faqA12),
      _FaqItem(Icons.notifications_none_rounded, L.faqQ13, L.faqA13),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(L.settingsFaq),
        centerTitle: false,
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        // ── Questions / réponses ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(L.faqSectionLabel,
              style: text.titleSmall?.copyWith(
                  color: scheme.primary, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
        ),
        for (final it in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SettingExpandable(
              boxed: true,
              icon: it.icon,
              title: it.question,
              body: Text(it.answer,
                  style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant, height: 1.5)),
            ),
          ),

        const SizedBox(height: 16),

        // ── Badge open source ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(24),
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
