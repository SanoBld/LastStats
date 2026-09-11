// lib/services/favorites_folders_service.dart
// ══════════════════════════════════════════════════════════════════════════
//  Folders for the Favorites page: user-created groups with an emoji and a
//  color, tracks can belong to zero, one or several folders.
//
//  Storage is two SharedPreferences keys, both prefixed 'ls_' like every
//  other persisted setting in this app — which means BackupService already
//  exports and restores them automatically, no extra plumbing needed there.
//   • ls_fav_folders        → JSON list of folders (id, name, emoji, color)
//   • ls_fav_track_folders  → JSON map: track key → list of folder ids
// ══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavFolder {
  final String id;
  String name;
  String emoji;
  int colorValue; // ARGB, so it survives JSON round-trips cleanly

  FavFolder({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'emoji': emoji, 'color': colorValue};

  factory FavFolder.fromJson(Map<String, dynamic> j) => FavFolder(
    id:         (j['id']    ?? '').toString(),
    name:       (j['name']  ?? '').toString(),
    emoji:      (j['emoji'] ?? '📁').toString(),
    colorValue: (j['color'] is num) ? (j['color'] as num).toInt() : 0xFF6750A4,
  );
}

// Curated palette so folders stay legible against both light and dark
// surfaces — mostly Material-ish tones, nothing too washed out or too neon.
const List<int> kFavFolderColors = [
  0xFFE57373, 0xFFF06292, 0xFFBA68C8, 0xFF9575CD, 0xFF7986CB,
  0xFF64B5F6, 0xFF4FC3F7, 0xFF4DD0E1, 0xFF4DB6AC, 0xFF81C784,
  0xFFAED581, 0xFFDCE775, 0xFFFFD54F, 0xFFFFB74D, 0xFFA1887F,
];

// A handful of emoji that make sense for music folders. Not exhaustive on
// purpose — the text field next to it accepts literally any emoji too, this
// is just a fast-tap shortlist.
const List<String> kFavFolderEmojis = [
  '📁', '⭐', '❤️', '🔥', '🎧', '🎤', '🎸', '🎹', '🎷', '🥁',
  '🌙', '☀️', '🌧️', '💤', '🏃', '🚗', '📚', '💪', '🎉', '😢',
];

class FavoritesFoldersService {
  FavoritesFoldersService._();

  static const _kFoldersKey = 'ls_fav_folders';
  static const _kAssignKey  = 'ls_fav_track_folders';

  // Folder list, and the track→folders assignment map, both kept live so
  // every part of the favorites page updates together without re-reading
  // SharedPreferences on every rebuild.
  static final ValueNotifier<List<FavFolder>> foldersNotifier = ValueNotifier([]);
  static final ValueNotifier<Map<String, List<String>>> assignNotifier = ValueNotifier({});

  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final p = await SharedPreferences.getInstance();

    final foldersRaw = p.getString(_kFoldersKey);
    if (foldersRaw != null && foldersRaw.isNotEmpty) {
      try {
        final list = (jsonDecode(foldersRaw) as List)
            .map((e) => FavFolder.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        foldersNotifier.value = list;
      } catch (_) {}
    }

    final assignRaw = p.getString(_kAssignKey);
    if (assignRaw != null && assignRaw.isNotEmpty) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(assignRaw));
        assignNotifier.value = decoded.map(
            (k, v) => MapEntry(k, List<String>.from(v as List)));
      } catch (_) {}
    }
  }

  static Future<void> _persistFolders() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kFoldersKey,
        jsonEncode(foldersNotifier.value.map((f) => f.toJson()).toList()));
  }

  static Future<void> _persistAssign() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAssignKey, jsonEncode(assignNotifier.value));
  }

  // ── Folder CRUD ────────────────────────────────────────────────────────

  static Future<FavFolder> createFolder(String name, String emoji, int colorValue) async {
    await ensureLoaded();
    final folder = FavFolder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? '📁' : name.trim(),
      emoji: emoji,
      colorValue: colorValue,
    );
    foldersNotifier.value = [...foldersNotifier.value, folder];
    await _persistFolders();
    return folder;
  }

  static Future<void> updateFolder(String id, {String? name, String? emoji, int? colorValue}) async {
    await ensureLoaded();
    foldersNotifier.value = foldersNotifier.value.map((f) {
      if (f.id != id) return f;
      return FavFolder(
        id: f.id,
        name: name ?? f.name,
        emoji: emoji ?? f.emoji,
        colorValue: colorValue ?? f.colorValue,
      );
    }).toList();
    await _persistFolders();
  }

  static Future<void> deleteFolder(String id) async {
    await ensureLoaded();
    foldersNotifier.value = foldersNotifier.value.where((f) => f.id != id).toList();
    await _persistFolders();
    // Clean up any track assignments pointing at the deleted folder.
    final updated = <String, List<String>>{};
    for (final e in assignNotifier.value.entries) {
      final remaining = e.value.where((fid) => fid != id).toList();
      if (remaining.isNotEmpty) updated[e.key] = remaining;
    }
    assignNotifier.value = updated;
    await _persistAssign();
  }

  // ── Track ↔ folder assignment ─────────────────────────────────────────

  static List<String> foldersForTrack(String trackKey) =>
      assignNotifier.value[trackKey] ?? const [];

  static Future<void> setFoldersForTrack(String trackKey, List<String> folderIds) async {
    await ensureLoaded();
    final updated = Map<String, List<String>>.from(assignNotifier.value);
    if (folderIds.isEmpty) {
      updated.remove(trackKey);
    } else {
      updated[trackKey] = folderIds;
    }
    assignNotifier.value = updated;
    await _persistAssign();
  }

  static Future<void> toggleTrackInFolder(String trackKey, String folderId) async {
    final current = List<String>.from(foldersForTrack(trackKey));
    if (current.contains(folderId)) {
      current.remove(folderId);
    } else {
      current.add(folderId);
    }
    await setFoldersForTrack(trackKey, current);
  }

  /// Drop a track from every folder — used when a track is unloved, so it
  /// doesn't linger orphaned in a folder if it's later re-loved.
  static Future<void> clearTrack(String trackKey) => setFoldersForTrack(trackKey, const []);
}
