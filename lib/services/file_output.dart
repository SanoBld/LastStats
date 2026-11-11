// lib/services/file_output.dart
// Files written by the AI: ```file:name.ext ... ``` blocks.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GeneratedFile {
  final String name;
  final String content;
  const GeneratedFile(this.name, this.content);
}

class FileOutput {
  static final _re = RegExp(r'```file:([^\s`]+)[ \t]*\n([\s\S]*?)```');

  static final _ask = RegExp(
      r'fichier|file|télécharg|telecharg|download|export|datei|archivo|descarg|\.(txt|csv|json|md|xlsx?|docx?|pdf|py|js|html|xml)\b|excel|tableur|spreadsheet|tabelle|hoja de c',
      caseSensitive: false);

  static String hide(String text) => text.replaceAll(_re, '').trim();

  static bool requested(String userText) => _ask.hasMatch(userText);

  /// Turns file blocks into normal code blocks (used when no file was asked for).
  static String strip(String text) =>
      text.replaceAll(RegExp(r'```file:[^\s`]+[ \t]*\n?'), '```\n');

  static List<GeneratedFile> extract(String text) => [
        for (final m in _re.allMatches(text))
          GeneratedFile(m.group(1)!.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_'), m.group(2)!),
      ];

  // Returns true when saved.
  static Future<bool> save(GeneratedFile f) async {
    final bytes = Uint8List.fromList(utf8.encode(f.content));
    final path = await FilePicker.platform.saveFile(fileName: f.name, bytes: bytes);
    if (path == null) return false;
    // Desktop: the picker only gives a path, so write the file ourselves.
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await File(path).writeAsBytes(bytes);
    }
    return true;
  }
}
