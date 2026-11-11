// lib/services/reset.dart
// Reset buttons (always behind confirmations).
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_state.dart';
import '../l10n/l10n.dart';
import '../supported_locales.dart';
import 'chat_store.dart';
import 'memory_store.dart';
import 'model_manager.dart';

class ResetService {
  static Future<bool> confirm(BuildContext context, String body, {String? title}) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: Text(title ?? tr('confirm_title')),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('confirm_yes'))),
        ],
      ),
    );
    return r == true;
  }

  static Future<bool> _typeWord(BuildContext context) async {
    final c = TextEditingController();
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          icon: const Icon(Icons.delete_forever_rounded),
          title: Text(tr('reset_all')),
          content: TextField(controller: c, autofocus: true, onChanged: (_) => set(() {}), decoration: InputDecoration(hintText: tr('reset_all_3'))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'))),
            FilledButton(
              onPressed: c.text.trim().toUpperCase() == 'RESET' ? () => Navigator.pop(ctx, true) : null,
              child: Text(tr('confirm_yes')),
            ),
          ],
        ),
      ),
    );
    c.dispose();
    return r == true;
  }

  static Future<void> _remove(List<String> keys) async {
    final p = await SharedPreferences.getInstance();
    for (final k in keys) {
      await p.remove(k);
    }
  }

  static Future<void> appearance() async {
    themeModeNotifier.value = themeFromString(null);
    accentNotifier.value = accentFromString(null);
    useDynamicColorNotifier.value = false;
    colorHarmonyNotifier.value = 'mono';
    oledModeNotifier.value = false;
    textScaleNotifier.value = 1.0;
    appFontNotifier.value = 'GoogleSansFlex';
    imageShapeNotifier.value = 'mix';
    hapticFeedbackNotifier.value = true;
    pcModeNotifier.value = 'auto';
    materialShapesNotifier.value = true;
    await _remove(['pc_theme', 'pc_accent', 'pc_use_dynamic_color', 'pc_color_harmony', 'pc_oled_mode', 'pc_text_scale',
      'pc_app_font', 'pc_image_shape', 'pc_haptic_feedback', 'pc_layout', 'pc_shapes']);
  }

  /// Three confirmations, then wipes everything. Returns true when done.
  static Future<bool> fullFlow(BuildContext context) async {
    if (!await confirm(context, tr('reset_all_1'), title: tr('reset_all'))) return false;
    if (!context.mounted || !await confirm(context, tr('reset_all_2'))) return false;
    if (!context.mounted || !await _typeWord(context)) return false;
    await appearance();
    final p = await SharedPreferences.getInstance();
    await p.clear();
    await ChatStore.instance.clearAll();
    await MemoryStore.instance.clear();
    for (final m in List.of(ModelManager.instance.installed)) {
      await ModelManager.instance.delete(m.id);
    }
    final dev = PlatformDispatcher.instance.locale.languageCode;
    localeNotifier.value = kSupportedLocales.any((l) => l.code == dev) ? dev : 'en';
    displayNameNotifier.value = '';
    systemPromptNotifier.value = kDefaultSystemPrompt;
    temperatureNotifier.value = 0.7;
    maxTokensNotifier.value = 1024;
    contextSizeNotifier.value = 4096;
    streamResponsesNotifier.value = true;
    autoTitleNotifier.value = true;
    sendOnEnterNotifier.value = true;
    webSearchNotifier.value = false;
    memoryEnabledNotifier.value = true;
    webMaxSourcesNotifier.value = 8;
    autoSpeakNotifier.value = false;
    activeModelNotifier.value = '';
    hfTokenNotifier.value = '';
    hfEndpointNotifier.value = kDefaultHfEndpoint;
    return true;
  }
}
