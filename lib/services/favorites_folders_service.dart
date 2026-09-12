// lib/services/favorites_folders_service.dart
// ══════════════════════════════════════════════════════════════════════════
//  Folders now live in their own page (accessed from Search), not in
//  Favorites. A folder holds tracks only, saved from search results or
//  from any track card. Each track can be in several folders at once.
//
//  Storage stays on plain SharedPreferences keys, all prefixed 'ls_' so the
//  existing BackupService picks them up automatically (it already scans
//  every 'ls_*' key). No extra code needed there.
//   • ls_fav_folders      → JSON list of folders (id, name, emoji, color, desc)
//   • ls_folder_items     → JSON map: track key → list of folder ids
//   • ls_folder_item_meta → JSON map: track key → {name, artist, image, addedAt}
//     (meta is needed so a folder can display a track even if it never
//     appears again in a later search)
// ══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavFolder {
  final String id;
  String name;
  String emoji;
  int colorValue; // ARGB, so it survives JSON round-trips cleanly
  String description;

  FavFolder({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    this.description = '',
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'emoji': emoji, 'color': colorValue, 'desc': description};

  factory FavFolder.fromJson(Map<String, dynamic> j) => FavFolder(
    id:          (j['id']    ?? '').toString(),
    name:        (j['name']  ?? '').toString(),
    emoji:       (j['emoji'] ?? '📁').toString(),
    colorValue:  (j['color'] is num) ? (j['color'] as num).toInt() : 0xFF6750A4,
    description: (j['desc']  ?? '').toString(),
  );
}

/// Small snapshot of a saved track, just enough to show it in a folder list
/// without needing to hit the API again. Folders only hold tracks.
class FolderItem {
  final String key;
  final String name;
  final String artist;
  final String image;
  final int addedAt;    // epoch ms, used to sort "recent first" in a folder

  FolderItem({
    required this.key,
    required this.name,
    required this.artist,
    required this.image,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() =>
      {'name': name, 'artist': artist, 'image': image, 'addedAt': addedAt};

  factory FolderItem.fromJson(String key, Map<String, dynamic> j) => FolderItem(
    key:     key,
    name:    (j['name']   ?? '').toString(),
    artist:  (j['artist'] ?? '').toString(),
    image:   (j['image']  ?? '').toString(),
    addedAt: (j['addedAt'] is num) ? (j['addedAt'] as num).toInt() : 0,
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
  static const _kAssignKey  = 'ls_folder_items';
  static const _kMetaKey    = 'ls_folder_item_meta';
  static const _kOrderKey   = 'ls_folder_order';

  /// Build a stable key for a track. Kept as a function (rather than just
  /// using name+artist) in case a non-track key format is ever needed.
  static String itemKey(String name, String artist) =>
      '${artist.trim().toLowerCase()}|${name.trim().toLowerCase()}';

  // Folder list, item→folders assignment, and item metadata — all kept
  // live so every part of the UI updates together without re-reading
  // SharedPreferences on every rebuild.
  static final ValueNotifier<List<FavFolder>> foldersNotifier = ValueNotifier([]);
  static final ValueNotifier<Map<String, List<String>>> assignNotifier = ValueNotifier({});
  static final ValueNotifier<Map<String, FolderItem>> metaNotifier = ValueNotifier({});
  // Manual drag order per folder: folder id → ordered list of track keys.
  static final ValueNotifier<Map<String, List<String>>> orderNotifier = ValueNotifier({});

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

    final metaRaw = p.getString(_kMetaKey);
    if (metaRaw != null && metaRaw.isNotEmpty) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(metaRaw));
        metaNotifier.value = decoded.map((k, v) =>
            MapEntry(k, FolderItem.fromJson(k, Map<String, dynamic>.from(v))));
      } catch (_) {}
    }

    final orderRaw = p.getString(_kOrderKey);
    if (orderRaw != null && orderRaw.isNotEmpty) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(orderRaw));
        orderNotifier.value = decoded.map(
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

  static Future<void> _persistMeta() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kMetaKey,
        jsonEncode(metaNotifier.value.map((k, v) => MapEntry(k, v.toJson()))));
  }

  static Future<void> _persistOrder() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kOrderKey, jsonEncode(orderNotifier.value));
  }

  // ── Folder CRUD ────────────────────────────────────────────────────────

  static Future<FavFolder> createFolder(String name, String emoji, int colorValue, {String description = ''}) async {
    await ensureLoaded();
    final folder = FavFolder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? '📁' : name.trim(),
      emoji: emoji,
      colorValue: colorValue,
      description: description.trim(),
    );
    foldersNotifier.value = [...foldersNotifier.value, folder];
    await _persistFolders();
    return folder;
  }

  static Future<void> updateFolder(String id, {String? name, String? emoji, int? colorValue, String? description}) async {
    await ensureLoaded();
    foldersNotifier.value = foldersNotifier.value.map((f) {
      if (f.id != id) return f;
      return FavFolder(
        id: f.id,
        name: name ?? f.name,
        emoji: emoji ?? f.emoji,
        colorValue: colorValue ?? f.colorValue,
        description: description ?? f.description,
      );
    }).toList();
    await _persistFolders();
  }

  static Future<void> deleteFolder(String id) async {
    await ensureLoaded();
    foldersNotifier.value = foldersNotifier.value.where((f) => f.id != id).toList();
    await _persistFolders();

    // Drop the folder from every item, then forget items left in no folder
    // at all — their metadata is only useful while they're saved somewhere.
    final updatedAssign = <String, List<String>>{};
    for (final e in assignNotifier.value.entries) {
      final remaining = e.value.where((fid) => fid != id).toList();
      if (remaining.isNotEmpty) updatedAssign[e.key] = remaining;
    }
    assignNotifier.value = updatedAssign;
    await _persistAssign();

    final updatedMeta = Map<String, FolderItem>.from(metaNotifier.value)
      ..removeWhere((k, _) => !updatedAssign.containsKey(k));
    metaNotifier.value = updatedMeta;
    await _persistMeta();

    final updatedOrder = Map<String, List<String>>.from(orderNotifier.value)
      ..remove(id);
    orderNotifier.value = updatedOrder;
    await _persistOrder();
  }

  // ── Item ↔ folder assignment ───────────────────────────────────────────

  static List<String> foldersForItem(String key) =>
      assignNotifier.value[key] ?? const [];

  static Future<void> setFoldersForItem(String key, List<String> folderIds, {FolderItem? meta}) async {
    await ensureLoaded();
    final updatedAssign = Map<String, List<String>>.from(assignNotifier.value);
    if (folderIds.isEmpty) {
      updatedAssign.remove(key);
    } else {
      updatedAssign[key] = folderIds;
    }
    assignNotifier.value = updatedAssign;
    await _persistAssign();

    final updatedMeta = Map<String, FolderItem>.from(metaNotifier.value);
    if (folderIds.isEmpty) {
      updatedMeta.remove(key);
    } else if (meta != null) {
      // Keep the original "added" time if this item was already saved
      // somewhere, so re-toggling a folder doesn't bump it to the top.
      final existing = updatedMeta[key];
      updatedMeta[key] = existing != null
          ? FolderItem(key: key, name: meta.name, artist: meta.artist,
              image: meta.image, addedAt: existing.addedAt)
          : meta;
    }
    metaNotifier.value = updatedMeta;
    await _persistMeta();
  }

  static Future<void> toggleItemInFolder(String key, String folderId, {required FolderItem meta}) async {
    final current = List<String>.from(foldersForItem(key));
    if (current.contains(folderId)) {
      current.remove(folderId);
    } else {
      current.add(folderId);
    }
    await setFoldersForItem(key, current, meta: meta);
  }

  /// Drop an item from every folder — used e.g. when a loved track is
  /// unloved, so it doesn't linger orphaned if it's later re-loved.
  static Future<void> clearItem(String key) => setFoldersForItem(key, const []);

  /// All items currently saved in one folder, most recently added last.
  static List<FolderItem> itemsInFolder(String folderId) {
    final keys = assignNotifier.value.entries
        .where((e) => e.value.contains(folderId))
        .map((e) => e.key);
    return keys.map((k) => metaNotifier.value[k])
        .whereType<FolderItem>().toList();
  }

  /// Items in a folder, respecting the user's manual drag order. Any item
  /// not yet in the saved order (e.g. just added) is appended at the end.
  static List<FolderItem> orderedItemsInFolder(String folderId) {
    final all = {for (final it in itemsInFolder(folderId)) it.key: it};
    final order = orderNotifier.value[folderId] ?? const [];
    final ordered = <FolderItem>[];
    for (final key in order) {
      final it = all.remove(key);
      if (it != null) ordered.add(it);
    }
    ordered.addAll(all.values); // anything new, not in the saved order yet
    return ordered;
  }

  static Future<void> reorderFolder(String folderId, List<String> keysInOrder) async {
    final updated = Map<String, List<String>>.from(orderNotifier.value);
    updated[folderId] = keysInOrder;
    orderNotifier.value = updated;
    await _persistOrder();
  }
}
