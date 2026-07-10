// lib/services/favorites_auth.dart
// ══════════════════════════════════════════════════════════════════════════
//  Shared flow to enable favorites (loved tracks): sign a token, send the
//  user to Last.fm to authorize the app, then exchange the token for a
//  session key. Used by both the setup screen and the account settings.
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';
import '../l10n/l10n.dart';
import 'lastfm_service.dart';

/// Runs the full authorization flow. Returns true on success.
Future<bool> connectFavorites(
  BuildContext context, {
  required String username,
  required String apiKey,
  required String secret,
}) async {
  final trimmed = secret.trim();
  if (trimmed.length != 32) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(L.favConnectInvalidSecret)));
    return false;
  }

  final service = LastFmService(apiKey: apiKey, username: username, secret: trimmed);

  try {
    final token = await service.getAuthToken();
    if (token.isEmpty) throw Exception('empty token');

    final uri = Uri.parse(service.authUrl(token));
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:   Text(L.favConnectDialogTitle),
        content: Text(L.favConnectDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(L.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(L.favConnectDialogConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    final sessionKey = await service.getSessionKey(token);
    if (sessionKey.isEmpty) throw Exception('empty session key');

    final p = await SharedPreferences.getInstance();
    await p.setString('ls_secret_key', trimmed);
    await p.setString('ls_session_key', sessionKey);
    secretKeyNotifier.value  = trimmed;
    sessionKeyNotifier.value = sessionKey;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L.favConnectSuccess)));
    }
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L.favConnectError)));
    }
    return false;
  }
}

/// Clears the secret + session key, disabling favorites.
Future<void> disconnectFavorites() async {
  final p = await SharedPreferences.getInstance();
  await p.remove('ls_secret_key');
  await p.remove('ls_session_key');
  secretKeyNotifier.value  = '';
  sessionKeyNotifier.value = '';
}
