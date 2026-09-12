// lib/services/scrobbles_file_cache.dart
// ══════════════════════════════════════════════════════════════════════════
//  ScrobblesFileCache — stockage multi-plateforme de l'historique complet
//
//  Stratégie de stockage :
//    • Premier lancement  → AllScrobblesService.loadAll() charge TOUT.
//    • Lancements suivants → AllScrobblesService.syncNew() ne charge que
//      les scrobbles postérieurs au dernier timestamp connu.
//    • Les données ne sont JAMAIS supprimées automatiquement (pas de TTL).
//      Seul ScrobblesFileCache.clear() ou une déconnexion vide le cache.
//
//  Backends :
//    • Web                             → IndexedDB (illimité)
//    • Natif (Android / iOS / Desktop) → fichiers via path_provider
//
//  Structure stockage :
//    Clé "year_YYYY" → {"v":2,"ts":…,"data":[[ts,"Track","Artist","Album"],…]}
//    Clé "meta"      → {"ts":…,"data":{"loaded_years":[…],"last_sync_ts":…}}
//
//  Rétrocompat :
//    v1 (anciens fichiers, timestamps seulement) → chargés comme ScrobbleRecord
//    sans métadonnées (track/artist/album vides). Re-téléchargement déclenché
//    par AllScrobblesService si track vide.
//
//  API publique :
//    • init()                   — charge en mémoire au démarrage
//    • getRecords(year)         → List<ScrobbleRecord>?
//    • getTimestamps(year)      → List<int>?  (dérivé des records)
//    • isYearCached(year)       → bool
//    • isYearComplete(year)     → bool  (records avec track+artist)
//    • getMeta()                → Map<String,dynamic>?
//    • setYear(year, records)   — persiste + met à jour la mémoire
//    • setMeta(meta)            — persiste + met à jour la mémoire
//    • clear()                  — vide tout (déconnexion)
//    • getDiskUsageBytes()      → Future<int>
//    • getTotalScrobbleCount()  → int
//    • pruneExpired()           — no-op (données permanentes)
// ══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/foundation.dart';

// Import conditionnel : le compilateur choisit le bon backend selon la cible.
import 'scrobbles_cache_backend_stub.dart'
    if (dart.library.io)   'scrobbles_cache_backend_native.dart'
    if (dart.library.html) 'scrobbles_cache_backend_web.dart';

// ══════════════════════════════════════════════════════════════════════════
//  Modèle
// ══════════════════════════════════════════════════════════════════════════

class ScrobbleRecord {
  final int    ts;      // Unix timestamp (secondes)
  final String track;
  final String artist;
  final String album;

  const ScrobbleRecord({
    required this.ts,
    required this.track,
    required this.artist,
    required this.album,
  });

  /// Sérialisation compacte : [ts, "track", "artist", "album"]
  List<dynamic> toList() => [ts, track, artist, album];

  /// Depuis le format compact v2 : [ts, track, artist, album]
  factory ScrobbleRecord.fromList(List<dynamic> l) => ScrobbleRecord(
        ts:     (l[0] as num).toInt(),
        track:  l.length > 1 ? (l[1] as String? ?? '') : '',
        artist: l.length > 2 ? (l[2] as String? ?? '') : '',
        album:  l.length > 3 ? (l[3] as String? ?? '') : '',
      );

  /// Depuis l'ancien format v1 (timestamp seul).
  factory ScrobbleRecord.fromTimestamp(int ts) =>
      ScrobbleRecord(ts: ts, track: '', artist: '', album: '');

  /// True if metadata present and not corrupted (old bug stored Map.toString()
  /// as artist, e.g. "{#text: Radiohead, mbid: ...}").
  bool get hasMetadata =>
      track.isNotEmpty && artist.isNotEmpty && !artist.startsWith('{');

  @override
  String toString() => '$ts · $artist — $track';
}

// Top-level so it can run in a separate isolate via compute(). Decodes and
// parses every year's raw JSON blob at once, off the UI thread — with years
// of scrobble history this was blocking startup for seconds on PC.
Map<int, List<ScrobbleRecord>> _decodeYearsRecords(Map<int, String> rawByYear) {
  final out = <int, List<ScrobbleRecord>>{};
  for (final entry in rawByYear.entries) {
    try {
      final decoded = jsonDecode(entry.value) as Map<String, dynamic>;
      final version = (decoded['v'] as num?)?.toInt() ?? 1;
      final records = ScrobblesFileCache._parseRecords(decoded['data'], version);
      if (records != null) out[entry.key] = records;
    } catch (_) {}
  }
  return out;
}

// Same idea but for the "ok" flag stored next to each year's data. Kept as
// a separate small pass since it needs the raw JSON, not the parsed records.
Map<int, bool> _decodeYearsOkFlags(Map<int, String> rawByYear) {
  final out = <int, bool>{};
  for (final entry in rawByYear.entries) {
    try {
      final decoded = jsonDecode(entry.value) as Map<String, dynamic>;
      // Old files never wrote "ok" -> default to true (don't force a
      // re-download of everything for people who already had cache before
      // this fix).
      out[entry.key] = decoded['ok'] as bool? ?? true;
    } catch (_) {}
  }
  return out;
}
// ══════════════════════════════════════════════════════════════════════════

/// Result of checking a backup's scrobble data for corruption BEFORE
/// importing anything (see [ScrobblesFileCache.checkRawForImport]).
class ScrobbleImportCheck {
  final List<int> validYears;
  final List<int> brokenYears;
  const ScrobbleImportCheck({required this.validYears, required this.brokenYears});
  bool get hasErrors => brokenYears.isNotEmpty;
}

class ScrobblesFileCache {
  ScrobblesFileCache._();

  static const _fileVersion = 2;

  // ── Cache mémoire ─────────────────────────────────────────────────────────
  static final Map<int, List<ScrobbleRecord>> _years = {};
  // True = this year finished downloading with no error. False = the
  // download broke early (network error), so it must be retried later even
  // if it looks "cached". Missing key = old file from before this flag
  // existed, we just trust it like before (assume complete).
  static final Map<int, bool>                 _yearOk = {};
  static Map<String, dynamic>?                _meta;
  static bool                                 _initialized = false;

  // ── Clés de stockage ──────────────────────────────────────────────────────
  static String _yearKey(int year) => 'year_$year';
  static const  _metaKey = 'meta';

  // ──────────────────────────────────────────────────────────────────────────
  //  Init — charge toutes les données en mémoire au démarrage.
  //  Les données ne sont jamais expirées ; tout ce qui est stocké est chargé.
  // ──────────────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // ── Méta ──────────────────────────────────────────────────────────────
      final metaRaw = await CacheBackend.read(_metaKey);
      if (metaRaw != null) {
        try {
          final decoded = jsonDecode(metaRaw) as Map<String, dynamic>;
          // 'data' contient loaded_years + last_sync_ts
          _meta = decoded['data'] as Map<String, dynamic>?;
        } catch (_) {}
      }

      // ── Années connues via la méta ─────────────────────────────────────────
      final years = _meta == null
          ? <int>[]
          : ((_meta!['loaded_years'] as List?)
                  ?.map((e) => (e as num).toInt())
                  .toList() ??
              []);

      // Read all raw blobs on the UI isolate (cheap I/O), then decode+parse
      // everything at once in a single background isolate — avoids both
      // blocking the UI thread and spawning one isolate per year.
      final rawByYear = <int, String>{};
      for (final year in years) {
        final raw = await CacheBackend.read(_yearKey(year));
        if (raw != null) rawByYear[year] = raw;
      }
      final parsed = await compute(_decodeYearsRecords, rawByYear);
      _years.addAll(parsed);
      final okFlags = await compute(_decodeYearsOkFlags, rawByYear);
      _yearOk.addAll(okFlags);

      debugPrint('[ScrobblesCache] ${_years.length} année(s) chargée(s) '
          '(${getTotalScrobbleCount()} scrobbles).');
    } catch (e) {
      debugPrint('[ScrobblesCache] Erreur init : $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Lecture (synchrone — depuis le cache mémoire)
  // ──────────────────────────────────────────────────────────────────────────

  /// Records complets pour [year], ou null si absent.
  static List<ScrobbleRecord>? getRecords(int year) => _years[year];

  /// Timestamps extraits des records (rétrocompat).
  static List<int>? getTimestamps(int year) =>
      _years[year]?.map((r) => r.ts).toList();

  static bool isYearCached(int year) => _years.containsKey(year);

  /// Vrai si tous les records de [year] ont leurs métadonnées (track+artist)
  /// ET si le téléchargement de cette année s'est terminé sans erreur.
  /// Retourne false si :
  ///   - la clé est absente (jamais chargée),
  ///   - le téléchargement a été coupé par une erreur réseau (voir [_yearOk],
  ///     rempli par setYear(..., complete: false)) — sinon une année qui a
  ///     planté au milieu du téléchargement reste bloquée pour toujours avec
  ///     seulement une poignée de scrobbles, et n'est jamais retentée,
  ///   - au moins un record manque ses métadonnées (ancien cache v1).
  /// Une année sans aucun scrobble (liste vide) MAIS bien terminée est
  /// considérée complète : elle a bien été chargée, il n'y avait rien.
  static bool isYearComplete(int year) {
    final records = _years[year];
    if (records == null) return false;          // jamais chargée
    if (_yearOk[year] == false) return false;   // téléchargement cassé
    if (records.isEmpty) return true;           // année blanche = complète
    return records.every((r) => r.hasMetadata);
  }

  static Map<String, dynamic>? getMeta() => _meta;

  /// Nombre total de scrobbles en cache (toutes années confondues).
  static int getTotalScrobbleCount() {
    int total = 0;
    for (final list in _years.values) {
      total += list.length;
    }
    return total;
  }

  /// Années présentes en cache, triées.
  static List<int> getCachedYears() => (_years.keys.toList()..sort());

  // ──────────────────────────────────────────────────────────────────────────
  //  Écriture (async — persiste dans le backend)
  // ──────────────────────────────────────────────────────────────────────────

  /// Save one year of scrobbles.
  /// [complete] tells if the download really finished (true) or broke early
  /// because of a network error (false). Keep it true by default so nothing
  /// else in the app has to change.
  static Future<void> setYear(int year, List<ScrobbleRecord> records,
      {bool complete = true}) async {
    _years[year]   = records;
    _yearOk[year]  = complete;
    try {
      final ts      = DateTime.now().millisecondsSinceEpoch;
      final payload = jsonEncode({
        'v':    _fileVersion,
        'ts':   ts,   // date d'écriture (informatif)
        'ok':   complete, // did the download finish without error?
        'data': records.map((r) => r.toList()).toList(),
      });
      await CacheBackend.write(_yearKey(year), payload);
    } catch (e) {
      debugPrint('[ScrobblesCache] Erreur écriture année=$year : $e');
    }
  }

  static Future<void> setMeta(Map<String, dynamic> meta) async {
    _meta = meta;
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      await CacheBackend.write(
        _metaKey,
        jsonEncode({'ts': ts, 'data': meta}),
      );
    } catch (e) {
      debugPrint('[ScrobblesCache] Erreur écriture meta : $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Stats stockage
  // ──────────────────────────────────────────────────────────────────────────

  static Future<int> getDiskUsageBytes() => CacheBackend.totalBytes();

  // ──────────────────────────────────────────────────────────────────────────
  //  Backup / restore support (used by BackupService)
  // ──────────────────────────────────────────────────────────────────────────

  /// Reads every cached year (+ meta) as raw JSON strings, so BackupService
  /// can embed the full scrobble history into a backup file.
  static Future<Map<String, String>> exportRawForBackup() async {
    final out = <String, String>{};
    for (final year in getCachedYears()) {
      final raw = await CacheBackend.read(_yearKey(year));
      if (raw != null) out[_yearKey(year)] = raw;
    }
    final metaRaw = await CacheBackend.read(_metaKey);
    if (metaRaw != null) out[_metaKey] = metaRaw;
    return out;
  }

  /// Tries to parse every "year_XXXX" entry from a backup's "scrobbles" map,
  /// WITHOUT writing anything, so the UI can warn the user first.
  static ScrobbleImportCheck checkRawForImport(Map<String, dynamic> raw) {
    final valid = <int>[];
    final broken = <int>[];
    for (final key in raw.keys) {
      if (!key.startsWith('year_')) continue;
      final year = int.tryParse(key.substring(5));
      if (year == null) continue;
      try {
        final decoded = jsonDecode(raw[key].toString()) as Map<String, dynamic>;
        final version = (decoded['v'] as num?)?.toInt() ?? 1;
        final records = _parseRecords(decoded['data'], version);
        if (records == null) {
          broken.add(year);
        } else {
          valid.add(year);
        }
      } catch (_) {
        broken.add(year);
      }
    }
    valid.sort();
    broken.sort();
    return ScrobbleImportCheck(validYears: valid, brokenYears: broken);
  }

  /// Imports scrobbles from a backup's "scrobbles" map. Years already on
  /// this device are MERGED (union by timestamp) rather than overwritten,
  /// so restoring on a new phone that already synced a few days keeps
  /// everything — nothing is lost either side.
  ///
  /// [mode]:
  ///   'keep'    → import every year, broken ones included (best effort).
  ///   'refetch' → drop broken years and mark them incomplete, so the app
  ///               re-downloads them from Last.fm on the next online sync.
  static Future<void> importRawFromBackup(
    Map<String, dynamic> raw, {
    required String mode,
  }) async {
    for (final key in raw.keys) {
      if (!key.startsWith('year_')) continue;
      final year = int.tryParse(key.substring(5));
      if (year == null) continue;

      List<ScrobbleRecord>? imported;
      bool importedOk = true;
      try {
        final decoded = jsonDecode(raw[key].toString()) as Map<String, dynamic>;
        final version = (decoded['v'] as num?)?.toInt() ?? 1;
        imported = _parseRecords(decoded['data'], version);
        importedOk = decoded['ok'] as bool? ?? true;
      } catch (_) {
        imported = null;
      }

      if (imported == null) {
        // Nothing usable for this year, whatever the mode.
        continue;
      }
      if (mode == 'refetch' && !importedOk) {
        // Broken year, user chose "skip + refetch online": don't import
        // it, and don't touch what's already cached either — just leave
        // it marked incomplete so a normal sync re-downloads it.
        continue;
      }

      // Merge with whatever is already on this device: union by
      // timestamp; if the same scrobble exists twice, prefer the copy
      // that actually has track/artist metadata.
      final existing = _years[year] ?? const <ScrobbleRecord>[];
      final byTs = <int, ScrobbleRecord>{for (final r in existing) r.ts: r};
      for (final r in imported) {
        final current = byTs[r.ts];
        if (current == null || (!current.hasMetadata && r.hasMetadata)) {
          byTs[r.ts] = r;
        }
      }
      final merged = byTs.values.toList()..sort((a, b) => a.ts.compareTo(b.ts));

      final complete = (_yearOk[year] ?? true) && importedOk;
      await setYear(year, merged, complete: complete);
    }

    // Update "loaded_years" so the newly imported years are recognized by
    // the rest of the app (AllScrobblesService etc.) on next read.
    final years = getCachedYears();
    await setMeta({..._meta ?? {}, 'loaded_years': years});
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Nettoyage
  // ──────────────────────────────────────────────────────────────────────────

  /// No-op — les données scrobbles sont permanentes.
  /// Seul [clear()] supprime les données (déconnexion explicite).
  static Future<void> pruneExpired() async {
    // Intentionnellement vide : pas de TTL sur l'historique.
  }

  /// Vide complètement le cache (mémoire + stockage).
  /// À appeler uniquement lors d'une déconnexion du compte.
  static Future<void> clear() async {
    _years.clear();
    _meta = null;
    _initialized = false;
    await CacheBackend.clearAll();
    debugPrint('[ScrobblesCache] Cache vidé.');
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Helpers privés
  // ──────────────────────────────────────────────────────────────────────────

  static List<ScrobbleRecord>? _parseRecords(dynamic data, int version) {
    if (data == null) return null;
    try {
      if (version >= 2) {
        // v2 : liste de listes [ts, track, artist, album]
        final list = data as List;
        return list
            .map((e) => ScrobbleRecord.fromList(e as List<dynamic>))
            .toList();
      } else {
        // v1 : liste de timestamps (int) — rétrocompat
        final list = data as List;
        return list
            .map((e) => ScrobbleRecord.fromTimestamp((e as num).toInt()))
            .toList();
      }
    } catch (_) {
      return null;
    }
  }
}