// lib/services/update_startup.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'update_service.dart';

/// Checks for an update right after app startup and, if one is found,
/// shows a simple dialog immediately (instead of waiting for the user
/// to open Settings).
class UpdateStartupChecker {
  static Future<void> run(GlobalKey<NavigatorState> navigatorKey) async {
    // Small delay so the dialog doesn't pop up before the first frame is drawn
    await Future.delayed(const Duration(milliseconds: 800));

    final info = await UpdateService.checkForUpdate();
    if (info == null) return;

    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Update available — v${info.version}'),
        content: Text(
          info.notes.isNotEmpty
              ? (info.notes.length > 200 ? '${info.notes.substring(0, 200)}…' : info.notes)
              : 'A new version of LastStats is available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final url = Uri.parse(info.hasApk ? info.apkUrl! : info.releaseUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }
}