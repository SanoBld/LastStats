// lib/services/backup.dart
// Export / import of one chat or of the personal memory (JSON files).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../app_state.dart';
import '../models/chat_models.dart';
import 'chat_store.dart';
import 'memory_store.dart';
import 'prefs.dart';

class Backup {
  static Future<bool> _save(String name, Map<String, dynamic> data) async {
    final bytes = Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(data)));
    final path = await FilePicker.platform.saveFile(fileName: name, bytes: bytes);
    if (path == null) return false;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await File(path).writeAsBytes(bytes);
    }
    return true;
  }

  static Future<bool> exportChat(Conversation c) {
    final safe = (c.title.isEmpty ? 'chat' : c.title).replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
    return _save('picochat_$safe.json', {'type': 'picochat-chat', 'chat': c.toJson()});
  }

  static Future<bool> exportMemory() => _save('picochat_memory.json', {
        'type': 'picochat-memory',
        'name': displayNameNotifier.value,
        'instructions': systemPromptNotifier.value,
        'facts': MemoryStore.instance.items,
      });

  /// Returns 'chat', 'memory' or null (cancelled / invalid file).
  static Future<String?> import() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'], withData: true);
    final bytes = res?.files.single.bytes;
    if (bytes == null) return null;
    try {
      final j = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (j['type'] == 'picochat-chat') {
        final c = Conversation.fromJson(Map<String, dynamic>.from(j['chat'] as Map));
        final copy = Conversation.fromJson({...c.toJson(), 'id': newId()});
        ChatStore.instance.importChat(copy);
        return 'chat';
      }
      if (j['type'] == 'picochat-memory') {
        await MemoryStore.instance.replaceAll(((j['facts'] as List?) ?? []).whereType<String>().toList());
        final style = j['instructions'];
        if (style is String && style.isNotEmpty) {
          systemPromptNotifier.value = style;
          await savePref('pc_system_prompt', style);
        }
        final name = j['name'];
        if (name is String && name.isNotEmpty && displayNameNotifier.value.isEmpty) {
          displayNameNotifier.value = name;
          await savePref('pc_display_name', name);
        }
        return 'memory';
      }
    } catch (_) {}
    return null;
  }
}
