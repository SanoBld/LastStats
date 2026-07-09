// lib/screens/notification_detail_page.dart
//
// Big, full-screen view of a notification — pushed when the user taps a
// notification (foreground/background tap, or cold-start launch). Shows the
// full title and body large, type-aware icon/color, and a button to open the
// link if the notification carries one (updates, news items with a URL…).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/l10n.dart';

class NotificationDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const NotificationDetailPage({super.key, required this.data});

  // Maps a notification 'type' (and 'newsType' for news items) to an icon
  // and a color. Colors mirror the dashboard's news sheet for consistency.
  (IconData, Color) _style() {
    final type     = (data['type']     ?? '').toString();
    final newsType = (data['newsType'] ?? '').toString();

    if (type == 'news') {
      return switch (newsType) {
        'feature' => (Icons.auto_awesome_rounded,  const Color(0xFF7C3AED)),
        'fix'     => (Icons.build_circle_outlined, const Color(0xFFD97706)),
        'update'  => (Icons.system_update_rounded, const Color(0xFF059669)),
        'alert'   => (Icons.warning_amber_rounded, const Color(0xFFDC2626)),
        _         => (Icons.info_outline_rounded,  const Color(0xFF1D4ED8)),
      };
    }
    return switch (type) {
      'milestone' => (Icons.flag_rounded,          const Color(0xFFD51007)),
      'grand'     => (Icons.emoji_events_rounded,  const Color(0xFFE65100)),
      'daily'     => (Icons.today_rounded,         const Color(0xFFD51007)),
      'weekly'    => (Icons.date_range_rounded,    const Color(0xFFD51007)),
      'update'    => (Icons.system_update_rounded, const Color(0xFF059669)),
      _           => (Icons.notifications_rounded, const Color(0xFFD51007)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    final title = (data['title'] ?? '').toString();
    final body  = (data['body']  ?? '').toString();
    final url   = (data['url']   ?? '').toString();
    final date  = (data['date']  ?? '').toString();
    final emoji = (data['emoji'] ?? '').toString();
    final (icon, color) = _style();

    return Scaffold(
      appBar: AppBar(
        title: Text(L.notifDetailTitle),
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          // Big icon / emoji badge
          Center(
            child: Container(
              width: 84, height: 84,
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: emoji.isNotEmpty
                    ? Text(emoji, style: const TextStyle(fontSize: 38))
                    : Icon(icon, size: 38, color: color),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title — large
          Text(
            title,
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),

          if (date.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              date,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],

          if (body.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color:        scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.35)),
              ),
              child: Text(
                body,
                style: text.bodyLarge?.copyWith(height: 1.5),
              ),
            ),
          ],

          if (url.isNotEmpty) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                final uri = Uri.tryParse(url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon:  const Icon(Icons.open_in_new_rounded),
              label: Text(L.notifDetailOpenLink),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ],
      ),
    );
  }
}