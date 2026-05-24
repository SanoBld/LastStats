// lib/services/scrobbles_file_cache.dart
// ══════════════════════════════════════════════════════════════════════════
//  ScrobblesFileCache — stockage fichier des timestamps d'historique
//
//  Remplace SharedPreferences pour les lourdes listes allscrobbles_YYYY.
//  Chaque année est stockée dans un fichier JSON dédié sur le disque,
//  sans alourdir le _warmUp() global de DataCache.
//
//  Structure :
//    {appSupportDir}/scrobbles/{year}.json  → {"ts":…, "data":[int,…]}
//    {appSupportDir}/scrobbles/meta.json    → {"ts":…, "data":{…}}
//
//  TTL :
//    Année en cours  → 1 h    (rechargée souvent pour les nouveaux scrobbles)
//    Années passées  → 90 j   (données immuables)
//    Méta            → 24 h
//
//  API publique (tout synchrone après init) :
//    • init()              — charge en mémoire au démarrage (à appeler une fois)
//    • pruneExpired()      — nettoyage non-bloquant (fire-and-forget)
//    • getTimestamps(year) → List<int>?   (lecture mémoire instantanée)
//    • isYearCached(year)  → bool
//    • getMeta()           → Map<String,dynamic>?
//    • setYear(year, ts)   — persiste + met à jour la mémoire
//    • setMeta(meta)       — persiste + met à jour la mémoire
//    • clear()             — vide tout (mémoire + disque)
// ══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ScrobblesFileCache {
  ScrobblesFileCache._();

  // ── TTL (ms) ──────────────────────────────────────────────────────────────
  static const _ttlCurrentMs = 60 * 60 * 1000;               // 1 h
  static const _ttlPastMs    = 90 * 24 * 60 * 60 * 1000;     // 90 j
  static const _ttlMetaMs    = 24 * 60 * 60 * 1000;          // 24 h

  // ── Cache mémoire ─────────────────────────────────────────────────────────
  static final Map<int, List<int>> _years = {};
  static Map<String, dynamic>?     _meta;

  // ── Répertoire de travail ─────────────────────────────────────────────────
  static Directory? _dir;
  static bool       _initialized = false;

  // ──────────────────────────────────────────────────────────────────────────
  //  Init
  // ──────────────────────────────────────────────────────────────────────────

  /// Charge les entrées valides depuis le disque en mémoire.
  /// À appeler une seule fois dans main() avant runApp().
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final dir = await _ensureDir();
      final now = DateTime.now().millisecondsSinceEpoch;

      // ── Méta ──────────────────────────────────────────────────────────────
      final mf = _metaFile(dir);
      if (mf.existsSync()) {
        try {
          final raw = jsonDecode(mf.readAsStringSync()) as Map<String, dynamic>;
          final ts  = (raw['ts'] as num?)?.toInt() ?? 0;
          if ((now - ts) <= _ttlMetaMs) {
            _meta = raw['data'] as Map<String, dynamic>?;
          }
        } catch (_) {}
      }

      // ── Années listées dans la méta ────────────────────────────────────────
      final years = _meta == null
          ? <int>[]
          : ((_meta!['loaded_years'] as List?)
                  ?.map((e) => (e as num).toInt())
                  .toList() ??
              []);

      for (final year in years) {
        final f = _yearFile(dir, year);
        if (!f.existsSync()) continue;
        try {
          final raw = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
          final ts  = (raw['ts'] as num?)?.toInt() ?? 0;
          if ((now - ts) > _ttlOf(year)) continue; // expiré
          final data = (raw['data'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList();
          if (data != null) _years[year] = data;
        } catch (_) {}
      }

      debugPrint('[ScrobblesCache] ${_years.length} année(s) chargée(s) depuis le disque.');
    } catch (e) {
      debugPrint('[ScrobblesCache] Erreur init : $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Lecture (synchrone — depuis le cache mémoire)
  // ──────────────────────────────────────────────────────────────────────────

  static List<int>?            getTimestamps(int year) => _years[year];
  static bool                  isYearCached(int year)  => _years.containsKey(year);
  static Map<String, dynamic>? getMeta()               => _meta;

  // ──────────────────────────────────────────────────────────────────────────
  //  Écriture (async — disque + mémoire)
  // ──────────────────────────────────────────────────────────────────────────

  /// Persiste les timestamps d'une année et met à jour le cache mémoire.
  static Future<void> setYear(int year, List<int> timestamps) async {
    _years[year] = timestamps;
    try {
      final dir = await _ensureDir();
      final ts  = DateTime.now().millisecondsSinceEpoch;
      await _yearFile(dir, year)
          .writeAsString(jsonEncode({'ts': ts, 'data': timestamps}));
    } catch (e) {
      debugPrint('[ScrobblesCache] Erreur écriture année=$year : $e');
    }
  }

  /// Persiste les métadonnées et met à jour le cache mémoire.
  static Future<void> setMeta(Map<String, dynamic> meta) async {
    _meta = meta;
    try {
      final dir = await _ensureDir();
      final ts  = DateTime.now().millisecondsSinceEpoch;
      await _metaFile(dir)
          .writeAsString(jsonEncode({'ts': ts, 'data': meta}));
    } catch (e) {
      debugPrint('[ScrobblesCache] Erreur écriture meta : $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Nettoyage
  // ──────────────────────────────────────────────────────────────────────────

  /// Supprime les fichiers expirés du disque. Non-bloquant (fire-and-forget).
  static Future<void> pruneExpired() async {
    try {
      final dir = await _ensureDir();
      final now = DateTime.now().millisecondsSinceEpoch;
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (name == 'meta.json') continue;
        final year = int.tryParse(name.replaceAll('.json', ''));
        if (year == null) continue;
        try {
          final raw = jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
          final ts  = (raw['ts'] as num?)?.toInt() ?? 0;
          if ((now - ts) > _ttlOf(year)) {
            await entity.delete();
            _years.remove(year);
            debugPrint('[ScrobblesCache] Fichier $year.json supprimé (expiré).');
          }
        } catch (_) {
          await entity.delete();
        }
      }
    } catch (_) {}
  }

  /// Vide tout le cache mémoire ET les fichiers disque.
  static Future<void> clear() async {
    _years.clear();
    _meta = null;
    try {
      final dir = await _ensureDir();
      if (dir.existsSync()) await dir.delete(recursive: true);
      await dir.create(recursive: true);
    } catch (_) {}
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Helpers privés
  // ──────────────────────────────────────────────────────────────────────────

  static int _ttlOf(int year) =>
      year == DateTime.now().year ? _ttlCurrentMs : _ttlPastMs;

  static Future<Directory> _ensureDir() async {
    if (_dir != null && _dir!.existsSync()) return _dir!;
    final base = await getApplicationSupportDirectory();
    _dir = Directory('${base.path}/scrobbles');
    await _dir!.create(recursive: true);
    return _dir!;
  }

  static File _yearFile(Directory dir, int year) =>
      File('${dir.path}/$year.json');

  static File _metaFile(Directory dir) =>
      File('${dir.path}/meta.json');
}