// lib/services/image_service.dart
//
// Resolves artwork URLs. Sources are tried one at a time, in priority order
// (Last.fm = last resort: its artist images are a grey star since 2019 and
// its albums are only ~300px):
//   Artist: Deezer > YouTube Music > TheAudioDB > MusicBrainz > Wikipedia > Last.fm
//   Album : Deezer > iTunes > YouTube Music > MusicBrainz > TheAudioDB > Wikipedia > Last.fm
//   Track : Deezer > iTunes > YouTube Music > TheAudioDB > album cover > Wikipedia > Last.fm
// Every source goes through its own queue ("lane", see _Lane) so a page that
// asks for 50 covers at once cannot flood — or get blocked by — the APIs.
// Downloads and caches image bytes via OfflineImageCache for offline use.
//
// Main entry points:
//   resolveArtist / resolveAlbum / resolveTrack  → URL string (fast, cached)
//   widgetImage(url, ...)                        → offline-capable Widget
//   prefetchBytes(url)                           → background download

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'api_http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_image_cache.dart';
import 'storage_manager.dart';
import '../l10n/extra_strings.dart';
import 'image_sizing.dart';

/// One artwork source in a lookup chain.
/// [run] returns: a URL (found) · '' (the source answered: no artwork) ·
/// null (the source could NOT answer: error, timeout, rate limit, paused).
class _S {
  final String name;
  final Future<String?> Function() run;
  const _S(this.name, this.run);
}

// ═════════════════════════════════════════════════════════════════════════════
//  Per-source scheduler
//
//  WHY: a ranking / search / history page asks for dozens of covers at once.
//  Every lookup used to fire its requests immediately (and in parallel over
//  3 sources), i.e. 100+ simultaneous HTTPS calls. iTunes (~20/min) and Deezer
//  (50 / 5 s) answered with 403/429/quota errors, the rest hit the 6 s timeout,
//  every source "failed", and the empty result was remembered → no artwork at
//  all, everywhere. The earlier client-side limiter made it worse: it DROPPED
//  requests (fake 429) and its waiting time counted against the HTTP timeout.
//
//  A lane never drops a request: it queues it, spaces the calls, and the
//  request timeout only starts once the request is really sent. After a
//  rate-limit answer (or a run of failures) the source is paused for a while
//  and the chain simply moves on to the next source.
// ═════════════════════════════════════════════════════════════════════════════
class _Lane {
  final int maxConcurrent;
  final int minGapMs;
  final int maxWaitMs; // longer queue than this → "unavailable", try later
  _Lane({required this.maxConcurrent, required this.minGapMs, this.maxWaitMs = 20000});

  int _active = 0;
  int _nextStart = 0;
  int _blockedUntil = 0;
  int _fails = 0;
  final Queue<Completer<void>> _waiters = Queue();

  static int _now() => DateTime.now().millisecondsSinceEpoch;

  bool get blocked => _blockedUntil > _now();

  void block(int ms) {
    final until = _now() + ms;
    if (until > _blockedUntil) _blockedUntil = until;
    _fails = 0;
  }

  void ok() => _fails = 0;

  // A few failures in a row (timeouts, 5xx…) → pause instead of piling up.
  void fail() {
    if (++_fails >= 6) block(30000);
  }

  void reset() {
    _blockedUntil = 0;
    _fails = 0;
  }

  int get _estimatedWaitMs {
    final ahead = _active + _waiters.length;
    final perSlot = minGapMs > 400 ? minGapMs : 400;
    return ((ahead / maxConcurrent).ceil() * perSlot);
  }

  /// Runs [task] when a slot is free. Returns null (= unavailable) when the
  /// source is paused or the queue is too long to be worth waiting for.
  Future<Object?> run(Future<Object?> Function() task) async {
    if (blocked || _estimatedWaitMs > maxWaitMs) return null;
    await _acquire();
    try {
      if (blocked) return null; // paused while we were queued
      return await task();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() async {
    if (_active >= maxConcurrent) {
      final c = Completer<void>();
      _waiters.add(c);
      await c.future; // the slot is handed over by _release (count unchanged)
    } else {
      _active++;
    }
    if (minGapMs > 0 && !blocked) {
      final now = _now();
      final start = _nextStart > now ? _nextStart : now;
      _nextStart = start + minGapMs;
      final wait = start - now;
      if (wait > 0) await Future.delayed(Duration(milliseconds: wait));
    }
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
    } else {
      _active--;
    }
  }
}

class ImageService {
  ImageService._();

  static const _placeholder = '2a96cbd8b46e442fc41c2b86b821562f';
  static const _timeout     = Duration(seconds: 8);
  // Hard cap for one full lookup, so a loading spinner never lasts forever.
  static const _maxResolve  = Duration(seconds: 30);
  static const _diskPrefix  = 'imgcache_';
  static const _diskTtlMs   = 7 * 24 * 60 * 60 * 1000;

  // In-memory URL cache (session).
  // BUG FIX: this used to be a plain Map with no size limit. On a long
  // session (lots of scrolling through history/charts/search), every
  // artist/album/track ever looked up stayed in RAM forever — this was
  // one of the causes of the app using more and more memory the longer
  // it stayed open. LinkedHashMap + a hard cap turns it into a simple
  // LRU cache: oldest-used entries are dropped once the cap is hit.
  static final Map<String, String> _mem = {};
  // Which source produced each cache key's URL — for the small attribution
  // label shown under artwork. Keyed by the same `key` used in `_mem`.
  static final Map<String, String> _sourceOf = {};
  // Max entries kept in RAM at once. Disk cache (SharedPreferences) still
  // has everything, so nothing is lost — it just gets re-read from disk
  // instead of staying in memory forever.
  static const int _memCap = 4000;

  // Marks [key] as recently used and trims the cache if it grew past the
  // cap. Call this every time an entry is read or written.
  static void _touch(String key) {
    final url = _mem.remove(key);
    if (url != null) _mem[key] = url; // re-insert = moves to "most recent"
    final src = _sourceOf.remove(key);
    if (src != null) _sourceOf[key] = src;
    while (_mem.length > _memCap) {
      final oldest = _mem.keys.first;
      _mem.remove(oldest);
      _sourceOf.remove(oldest);
    }
  }

  static SharedPreferences? _prefs;
  static Future<void>? _diskLoading;

  // Artist/album/track lookups that found nothing (or failed because a
  // source was rate-limited / offline). Remembered for a short time only:
  // before, an empty result was cached for the whole session, so one
  // transient failure meant "no artwork" until the app was restarted.
  static final Map<String, int> _negUntil = {};
  static const _negTtlMs = 10 * 60 * 1000;      // every source said "nothing"
  static const _negShortMs = 20 * 1000;          // some source was unavailable

  static void _markNegative(String key, int ms) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _negUntil[key] = now + ms;
    if (_negUntil.length > 2000) {
      _negUntil.removeWhere((_, t) => t < now);
    }
  }

  static bool _isNegative(String key) {
    final t = _negUntil[key];
    if (t == null) return false;
    if (t > DateTime.now().millisecondsSinceEpoch) return true;
    _negUntil.remove(key);
    return false;
  }

  // One lookup at a time per key: a list showing the same artist 20 times
  // used to run the whole source chain 20 times in parallel.
  static final Map<String, Future<String>> _pending = {};
  static Future<String> _once(String key, Future<String> Function() run) {
    final running = _pending[key];
    if (running != null) return running;
    final f = run().whenComplete(() => _pending.remove(key));
    _pending[key] = f;
    return f;
  }

  // ── URL cache (metadata only, not bytes) ──────────────────────────────────

  static Future<void> _ensureDiskCache() => _diskLoading ??= _loadDiskCache();

  static Future<void> _loadDiskCache() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final k in _prefs!.getKeys()) {
        if (!k.startsWith(_diskPrefix)) continue;
        final raw = _prefs!.getString(k);
        if (raw == null) continue;
        try {
          final e   = jsonDecode(raw) as Map<String, dynamic>;
          final ts  = (e['ts'] as num?)?.toInt() ?? 0;
          final url = (e['url'] as String?) ?? '';
          final src = (e['source'] as String?) ?? '';
          // Entries cached before source-tracking existed have no 'source'
          // field — rather than show a guessed/fake source for those, drop
          // them so they get re-resolved (and properly tagged) next time.
          if (url.isEmpty || src.isEmpty || url.contains(_placeholder) || (now - ts) > _diskTtlMs) {
            _prefs!.remove(k).ignore();
            continue;
          }
          _mem[k.substring(_diskPrefix.length)] = url;
          _sourceOf[k.substring(_diskPrefix.length)] = src;
        } catch (_) { _prefs!.remove(k).ignore(); }
      }
    } catch (_) {}
  }

  static String? _getUrl(String key) {
    final url = _mem[key];
    if (url != null) _touch(key); // mark as recently used, keep it in RAM
    return url;
  }

  static Future<String> _persistUrl(String key, String url, [String source = '']) async {
    if (url.isEmpty) {
      _markNegative(key, _negTtlMs);
      return url;
    }
    _negUntil.remove(key);
    _mem[key] = url;
    if (source.isNotEmpty) _sourceOf[key] = source;
    _touch(key);
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(
        '$_diskPrefix$key',
        jsonEncode({'url': url, 'ts': DateTime.now().millisecondsSinceEpoch, 'source': source}),
      );
    } catch (_) {}
    // Background download at list size (bigger sizes load on demand).
    _cacheBytes(sizedImageUrl(url, 120, 2.0));
    return url;
  }

  /// Human-readable, translated name of the source that provided the
  /// artwork currently cached for this artist/album/track — for the small
  /// gray attribution label shown under artwork. Returns '' if unknown.
  static String sourceLabel(String type, String artist, {String album = '', String track = ''}) {
    final key = switch (type) {
      'artist' => 'artist|$artist',
      'album'  => 'album|$artist|$album',
      'track'  => 'track|$artist|$track',
      _ => '',
    };
    final raw = _sourceOf[key];
    if (raw == null || raw.isEmpty) return '';
    return _sourceDisplayNames.containsKey(raw) ? tx('img_src_$raw') : '';
  }

  /// Bare brand name (e.g. "YouTube Music"), no "Source:" prefix — for
  /// composing into a longer label like "Artist · YouTube Music".
  static String sourceName(String type, String artist, {String album = '', String track = ''}) {
    final key = switch (type) {
      'artist' => 'artist|$artist',
      'album'  => 'album|$artist|$album',
      'track'  => 'track|$artist|$track',
      _ => '',
    };
    return _sourceDisplayNames[_sourceOf[key]] ?? '';
  }

  static const Map<String, String> _sourceDisplayNames = {
    'lastfm': 'Last.fm', 'ytmusic': 'YouTube Music', 'itunes': 'iTunes',
    'deezer': 'Deezer', 'audiodb': 'TheAudioDB', 'musicbrainz': 'MusicBrainz',
    'wikipedia': 'Wikipedia',
  };

  

  static void _cacheBytes(String url) {
    if (url.isEmpty) return;
    OfflineImageCache.imageProvider(url).then((_) {
      StorageManager.enforceQuota().ignore();
    }).ignore();
  }

  // ── Public: resolve URL ───────────────────────────────────────────────────
  // Source order (first answer wins, one source at a time):
  //   Artist: Deezer > YouTube Music > TheAudioDB > MusicBrainz > Wikipedia
  //   Album : Deezer > iTunes > YouTube Music > MusicBrainz > TheAudioDB > Wikipedia
  //   Track : Deezer > iTunes > YouTube Music > TheAudioDB > album cover > Wikipedia
  //   …and Last.fm's own picture when nothing else is found.
  // Deezer goes first because its limit (50 req / 5 s) is the most generous;
  // iTunes (~20 req / min) is kept for what Deezer does not know.

  static Future<String> resolveArtist(String artist, {String? lastfmUrl}) =>
      _once('artist|$artist', () => _resolve(
            key: 'artist|$artist',
            lastfmUrl: lastfmUrl,
            chain: () => [
              _S('deezer',      () => _deezerArtist(artist)),
              _S('ytmusic',     () => _ytMusicSearch(artist, 'artist', expectArtist: artist)),
              _S('audiodb',     () => _audioDbArtist(artist)),
              _S('musicbrainz', () => _mbArtistImage(artist)),
              _S('wikipedia',   () => _wikipediaImage(artist, expectName: artist)),
            ],
          )).timeout(_maxResolve, onTimeout: () => _ok(lastfmUrl) ? lastfmUrl! : '');

  static Future<String> resolveAlbum(String album, String artist, {String? lastfmUrl}) =>
      _once('album|$artist|$album', () => _resolve(
            key: 'album|$artist|$album',
            lastfmUrl: lastfmUrl,
            chain: () => [
              _S('deezer',      () => _deezerAlbum(album, artist)),
              _S('itunes',      () => _itunesSearch('$artist $album', 'album', null, artist, album)),
              _S('ytmusic',     () => _ytMusicSearch('$artist $album', 'album', expectArtist: artist, expectTitle: album)),
              _S('musicbrainz', () => _mbAlbum(album, artist)),
              _S('audiodb',     () => _audioDbAlbum(album, artist)),
              _S('wikipedia',   () => _wikipediaImage('$artist $album album', expectName: album)),
            ],
          )).timeout(_maxResolve, onTimeout: () => _ok(lastfmUrl) ? lastfmUrl! : '');

  static Future<String> resolveTrack(String track, String artist,
          {String? lastfmUrl, String album = ''}) =>
      _once('track|$artist|$track', () => _resolve(
            key: 'track|$artist|$track',
            lastfmUrl: lastfmUrl,
            chain: () => [
              _S('deezer',  () => _deezerTrack(track, artist)),
              _S('itunes',  () => _itunesSearch('$artist $track', 'song', null, artist, track)),
              _S('ytmusic', () => _ytMusicSearch('$artist $track', 'song', expectArtist: artist, expectTitle: track)),
              _S('audiodb', () => _audioDbTrack(track, artist)),
              if (album.isNotEmpty) _S('musicbrainz', () => _mbAlbum(album, artist)),
              _S('wikipedia', () => _wikipediaImage('$artist $track song', expectName: track)),
            ],
          )).timeout(_maxResolve, onTimeout: () => _ok(lastfmUrl) ? lastfmUrl! : '');

  // Shared lookup: memory/disk cache → source chain → Last.fm picture.
  //
  // A source that could not answer (null) is NOT the same as "no artwork":
  //   • nothing found and a source was unavailable → NOT remembered for long
  //     (20 s) and retried once after a short pause, so a rate-limit burst
  //     heals by itself instead of leaving blank covers for 10 minutes;
  //   • nothing found and every source answered → remembered 10 minutes.
  static Future<String> _resolve({
    required String key,
    required List<_S> Function() chain,
    String? lastfmUrl,
  }) async {
    await _ensureDiskCache();
    final mem = _getUrl(key);
    if (mem != null) return mem;
    if (_isNegative(key)) return _ok(lastfmUrl) ? lastfmUrl! : '';

    for (var attempt = 0; ; attempt++) {
      final r = await _pick(chain());
      final hit = r.hit;
      if (hit != null) return _persistUrl(key, hit.value, hit.key);

      if (_ok(lastfmUrl)) {
        if (!r.incomplete) return _persistUrl(key, lastfmUrl!, 'lastfm');
        // Show Last.fm's picture now, but do not pin it: a better source
        // may answer later.
        _markNegative(key, _negShortMs);
        return lastfmUrl!;
      }

      if (r.incomplete && attempt == 0) {
        await Future.delayed(const Duration(seconds: 4));
        final again = _getUrl(key); // another caller may have found it
        if (again != null) return again;
        continue;
      }
      _markNegative(key, r.incomplete ? _negShortMs : _negTtlMs);
      return '';
    }
  }

  // ── Source chain runner ───────────────────────────────────────────────────
  // Sources are tried one after the other (priority order). [incomplete] is
  // true when at least one of them could not answer.
  static Future<({MapEntry<String, String>? hit, bool incomplete})> _pick(
      List<_S> chain) async {
    var incomplete = false;
    for (final s in chain) {
      String? u;
      try {
        u = await s.run();
      } catch (_) {
        u = null;
      }
      if (u == null) {
        incomplete = true;
        continue;
      }
      if (_ok(u)) return (hit: MapEntry(s.name, u), incomplete: incomplete);
    }
    return (hit: null, incomplete: incomplete);
  }

  // ── Public: widget helper ─────────────────────────────────────────────────

  /// Drop-in replacement for Image.network — uses local cache when offline.
  static Widget widgetImage({
    required String url,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) => OfflineImageCache.image(
        url:         url,
        width:       width,
        height:      height,
        fit:         fit,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );

  // ── Public: force byte download ───────────────────────────────────────────

  /// Downloads and caches image bytes; enforces storage quota afterwards.
  static Future<void> prefetchBytes(String url) async {
    if (url.isEmpty) return;
    await OfflineImageCache.imageProvider(url);
    await StorageManager.enforceQuota();
  }

  // ── Cache stats ───────────────────────────────────────────────────────────

  static int  get urlCacheSize => _mem.length;
  static void clearUrlCache()  {
    _mem.clear(); _sourceOf.clear(); _negUntil.clear();
    for (final l in _lanes.values) { l.reset(); }
  }

  static Future<void> clearAllCache() async {
    _mem.clear();
    _sourceOf.clear();
    _negUntil.clear();
    for (final l in _lanes.values) { l.reset(); }
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final keys = _prefs!.getKeys().where((k) => k.startsWith(_diskPrefix)).toList();
      for (final k in keys) {
        await _prefs!.remove(k);
      }
    } catch (_) {}
    await OfflineImageCache.clear();
  }

  static Future<int> pruneExpired() async {
    int removed = 0;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final now  = DateTime.now().millisecondsSinceEpoch;
      final keys = _prefs!.getKeys().where((k) => k.startsWith(_diskPrefix)).toList();
      for (final k in keys) {
        final raw = _prefs!.getString(k);
        if (raw == null) { await _prefs!.remove(k); removed++; continue; }
        try {
          final e  = jsonDecode(raw) as Map<String, dynamic>;
          final ts = (e['ts'] as num?)?.toInt() ?? 0;
          if ((now - ts) > _diskTtlMs) {
            await _prefs!.remove(k);
            _mem.remove(k.substring(_diskPrefix.length));
            _sourceOf.remove(k.substring(_diskPrefix.length));
            removed++;
          }
        } catch (_) { await _prefs!.remove(k); removed++; }
      }
    } catch (_) {}
    return removed;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static bool _ok(String? url) =>
      url != null && url.isNotEmpty && !url.contains(_placeholder) && !_deezerEmpty(url);

  // Deezer serves a grey default image when it has no real picture.
  static bool _deezerEmpty(String u) =>
      u.contains('dzcdn.net') && (u.contains('//1000x1000') || u.contains('/images/artist//') ||
      u.contains('/images/cover//') || u.contains('d41d8cd98f00b204e9800998ecf8427e'));

  /// Artwork URL rewritten for the size it is shown at (logical px).
  static String sized(String url, double logicalPx, double dpr) =>
      OfflineImageCache.sized(url, logicalPx, dpr);

  // Normalizes a name for loose comparison: lowercase, strips diacritics,
  // drops a leading "the/a/le/la/les", keeps only letters/digits.
  static String _normalize(String s) {
    var n = s.toLowerCase().trim();
    const accents = 'àâäáãåèêëéìîïíòôöóõùûüúñçÀÂÄÁÃÅÈÊËÉÌÎÏÍÒÔÖÓÕÙÛÜÚÑÇ';
    const plain   = 'aaaaaaeeeeiiiiooooouuuuncAAAAAAEEEEIIIIOOOOOUUUUNC';
    for (var i = 0; i < accents.length; i++) {
      n = n.replaceAll(accents[i], plain[i]);
    }
    n = n.replaceFirst(RegExp(r'^(the|a|le|la|les)\s+'), '');
    return n.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  // Loose "is this actually about what we searched for" check — used to
  // reject mismatched results from third-party sources (the cause of
  // unrelated images showing up) rather than blindly trusting whatever
  // each API returns first.
  static bool _similar(String expected, String candidate) {
    final a = _normalize(expected);
    final b = _normalize(candidate);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    final shorter = a.length <= b.length ? a : b;
    final longer  = a.length <= b.length ? b : a;
    if (shorter.length >= 4 && longer.contains(shorter)) return true;
    return false;
  }

  // Searches YouTube Music. No public API exists for this — this hits the
  // same unofficial internal endpoint YouTube Music's own web player uses
  // (the one ytmusicapi/InnerTune/Metrolist rely on). It's not documented
  // or guaranteed by Google, so it can break without warning; iTunes/Deezer/
  // MusicBrainz below stay as solid fallbacks either way.
  //
  // Fixed after checking Metrolist's source: the actual request-building
  // code lives in an external submodule they don't ship in exports, so it
  // couldn't be copied directly — but their *response models* (included)
  // confirmed two real bugs here: missing API key/client headers (which was
  // silently failing every request — no logged error, just an empty
  // result), and only handling list results while an artist search's "top
  // result" comes back as a different JSON shape (a single "card", not a
  // list) that was never checked at all.
  static const _ytmApiKey = 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8';
  static const _ytmFilters = {
    'artist': 'EgWKAQIgAWoKEAMQBBAJEAoQBQ%3D%3D',
    'album':  'EgWKAQIYAWoKEAMQBBAJEAoQBQ%3D%3D',
    'song':   'EgWKAQIIAWoKEAMQBBAJEAoQBQ%3D%3D',
  };

  // ── Network layer (all sources go through their lane) ────────────────────
  //
  // Source functions below return:
  //   a URL  → found
  //   ''     → the source answered: it has no matching artwork
  //   null   → the source could not answer (error / timeout / rate limit /
  //            paused / queue too long). NOT a "no artwork" verdict.

  static final Map<String, _Lane> _lanes = {
    // Deezer: 50 req / 5 s per IP.
    'deezer':      _Lane(maxConcurrent: 4, minGapMs: 130),
    // iTunes: ~20 req / min per IP (Apple docs) → only a fallback source.
    'itunes':      _Lane(maxConcurrent: 1, minGapMs: 1800, maxWaitMs: 12000),
    // YouTube Music: unofficial endpoint, kept gentle.
    'ytmusic':     _Lane(maxConcurrent: 2, minGapMs: 350),
    // TheAudioDB free key: 30 req / min.
    'audiodb':     _Lane(maxConcurrent: 1, minGapMs: 2200, maxWaitMs: 8000),
    // MusicBrainz: 1 req / s.
    'musicbrainz': _Lane(maxConcurrent: 1, minGapMs: 1150, maxWaitMs: 10000),
    'wikimedia':   _Lane(maxConcurrent: 2, minGapMs: 250),
    'coverart':    _Lane(maxConcurrent: 2, minGapMs: 250),
  };

  static Future<Object?> _exchange(
      String api, Future<http.Response> Function() send) async {
    final lane = _lanes[api]!;
    try {
      final res = await send().timeout(_timeout);
      // Skipped by the optional client-side limiter of the API page.
      if (res.headers['x-laststats-skipped'] == '1') return null;
      final code = res.statusCode;
      if (code == 429 || code == 403 || code == 503) {
        lane.block(api == 'itunes' ? 60000 : 20000);
        return null;
      }
      if (code >= 500) {
        lane.fail();
        return null;
      }
      // Other 4xx (404, 400…): the source answered, it just has nothing.
      if (code != 200) {
        lane.ok();
        return const <String, dynamic>{};
      }
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      // Deezer answers HTTP 200 with {"error":{"code":4,...}} when over quota.
      if (api == 'deezer' && body is Map && body['error'] != null) {
        lane.block(8000);
        return null;
      }
      lane.ok();
      return body ?? const <String, dynamic>{};
    } catch (_) {
      lane.fail();
      return null;
    }
  }

  static Future<Object?> _getJson(String api, Uri uri, {Map<String, String>? headers}) =>
      _lanes[api]!.run(() => _exchange(api, () => ApiHttp.get(uri, headers: headers)));

  static Future<Object?> _postJson(String api, Uri uri,
          {Map<String, String>? headers, Object? body}) =>
      _lanes[api]!.run(() => _exchange(api, () => ApiHttp.post(uri, headers: headers, body: body)));

  /// HTTP status of a GET, or null when the source could not answer.
  static Future<int?> _statusOf(String api, Uri uri) async {
    final lane = _lanes[api]!;
    final r = await lane.run(() async {
      try {
        final res = await ApiHttp.get(uri).timeout(_timeout);
        if (res.headers['x-laststats-skipped'] == '1') return null;
        if (res.statusCode == 429 || res.statusCode == 503) {
          lane.block(20000);
          return null;
        }
        if (res.statusCode >= 500) {
          lane.fail();
          return null;
        }
        lane.ok();
        return res.statusCode;
      } catch (_) {
        lane.fail();
        return null;
      }
    });
    return r as int?;
  }

  static List _list(Object? json, String key) {
    if (json is Map) {
      final v = json[key];
      if (v is List) return v;
    }
    return const [];
  }

  static String _s(Object? v) => (v ?? '').toString();

  static Future<String?> _ytMusicSearch(
    String term,
    String type, {
    String? expectArtist,
    String? expectTitle,
  }) async {
    try {
      final data = await _postJson(
        'ytmusic',
        Uri.https('music.youtube.com', '/youtubei/v1/search', {'key': _ytmApiKey}),
        headers: {
          'Content-Type': 'application/json',
          'Origin': 'https://music.youtube.com',
          'Referer': 'https://music.youtube.com/',
          'X-YouTube-Client-Name': '67',
          'X-YouTube-Client-Version': '1.20240101.01.00',
          // Google's edge servers reject requests without a browser-like UA.
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
              'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        body: jsonEncode({
          'context': {
            'client': {
              'clientName': 'WEB_REMIX',
              'clientVersion': '1.20240101.01.00',
              'hl': 'en',
              'gl': 'US',
            }
          },
          'query': term,
          'params': _ytmFilters[type],
        }),
      );
      if (data == null) {
        debugLog('[ytmusic] unavailable for "$term" ($type)');
        return null;
      }
      if (data is! Map) return '';

      final sections = data['contents']?['tabbedSearchResultsRenderer']?['tabs']?[0]
          ?['tabRenderer']?['content']?['sectionListRenderer']?['contents'] as List?;
      if (sections == null) {
        debugLog('[ytmusic] no sections in response for "$term" — response shape may have changed');
        return '';
      }

      for (final section in sections) {
        // Artist searches usually surface a single "top result" card first —
        // a different shape than the regular list, and it was never checked.
        final card = section['musicCardShelfRenderer'];
        if (card != null) {
          final title = card['title']?['runs']?[0]?['text']?.toString() ?? '';
          final subtitle = card['subtitle']?['runs']?[0]?['text']?.toString() ?? '';
          final match = expectArtist == null ||
              _similar(expectArtist, type == 'artist' ? title : subtitle);
          if (match && (expectTitle == null || _similar(expectTitle, title))) {
            final url = _bestThumbnail(card['thumbnail']);
            if (url.isNotEmpty) return url;
          }
        }

        final items = section['musicShelfRenderer']?['contents'] as List?;
        if (items == null || items.isEmpty) continue;
        final item = items.first['musicResponsiveListItemRenderer'];
        if (item == null) continue;

        // First flex column = title (song/album) or artist name.
        final flexCols = item['flexColumns'] as List?;
        final title = flexCols?[0]?['musicResponsiveListItemFlexColumnRenderer']
            ?['text']?['runs']?[0]?['text']?.toString() ?? '';
        String subtitleArtist = '';
        if (flexCols != null && flexCols.length > 1) {
          final runs = flexCols[1]['musicResponsiveListItemFlexColumnRenderer']
              ?['text']?['runs'] as List?;
          if (runs != null && runs.isNotEmpty) subtitleArtist = runs.first['text']?.toString() ?? '';
        }

        if (expectArtist != null &&
            !_similar(expectArtist, type == 'artist' ? title : subtitleArtist)) {
          continue;
        }
        if (expectTitle != null && !_similar(expectTitle, title)) continue;

        final url = _bestThumbnail(item['thumbnail']);
        if (url.isNotEmpty) return url;
      }
      debugLog('[ytmusic] no matching result for "$term" ($type, expectArtist=$expectArtist, expectTitle=$expectTitle)');
      return '';
    } catch (e) {
      debugLog('[ytmusic] exception for "$term": $e');
      return '';
    }
  }

  // Mirrors Metrolist's ThumbnailRenderer.getThumbnailUrl() fallback chain:
  // regular thumbnail → animated thumbnail's backup → cropped-square variant.
  static String _bestThumbnail(dynamic thumbnailRenderer) {
    if (thumbnailRenderer == null) return '';
    final direct = thumbnailRenderer['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
    final animated = thumbnailRenderer['musicAnimatedThumbnailRenderer']
        ?['backupRenderer']?['thumbnail']?['thumbnails'] as List?;
    final cropped = thumbnailRenderer['croppedSquareThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
    final thumbs = direct ?? animated ?? cropped;
    if (thumbs == null || thumbs.isEmpty) return '';
    final raw = (thumbs.last['url'] ?? '').toString();
    if (raw.isEmpty) return '';
    return _upsizeYtThumbnail(raw);
  }

  // Bumps a YT thumbnail URL's resolution while keeping its original aspect
  // ratio — forcing a fixed w=h square (the old behavior) stretched any
  // non-square source (artist photos, banners) into a distorted square.
  static String _upsizeYtThumbnail(String url) {
    final m = RegExp(r'=w(\d+)-h(\d+)').firstMatch(url);
    if (m == null) return url;
    final w = int.tryParse(m.group(1)!) ?? 0;
    final h = int.tryParse(m.group(2)!) ?? 0;
    if (w <= 0 || h <= 0) return url;
    final scale = 1200 / (w > h ? w : h);
    final newW = (w * scale).round();
    final newH = (h * scale).round();
    return url.replaceFirst(RegExp(r'=w\d+-h\d+.*$'), '=w$newW-h$newH');
  }

  // Searches iTunes and only returns artwork if the result actually matches
  // who/what we asked for (expectArtist / expectTitle) — avoids grabbing the
  // first loosely-related hit when the catalog has an ambiguous match.
  static Future<String?> _itunesSearch(
    String term,
    String entity, [
    String? attribute,
    String? expectArtist,
    String? expectTitle,
  ]) async {
    try {
      final params = <String, String>{'term': term, 'entity': entity, 'limit': '1', 'media': 'music'};
      if (attribute != null) params['attribute'] = attribute;
      final j = await _getJson('itunes', Uri.https('itunes.apple.com', '/search', params));
      if (j == null) return null;
      final results = _list(j, 'results');
      if (results.isEmpty) return '';
      final item = results.first as Map;

      if (expectArtist != null && !_similar(expectArtist, _s(item['artistName']))) return '';
      if (expectTitle != null) {
        final titleField = entity == 'song' ? 'trackName' : 'collectionName';
        if (!_similar(expectTitle, _s(item[titleField]))) return '';
      }

      final raw = _s(item['artworkUrl100']);
      return raw.isEmpty ? '' : raw
          .replaceAll('100x100bb', '3000x3000bb')
          .replaceAll('100x100',   '3000x3000');
    } catch (_) { return ''; }
  }

  static Future<String?> _deezerArtist(String artist) async {
    try {
      final j = await _getJson('deezer',
          Uri.https('api.deezer.com', '/search/artist', {'q': artist, 'limit': '1'}));
      if (j == null) return null;
      final items = _list(j, 'data');
      if (items.isEmpty) return '';
      final item = items.first as Map;
      if (!_similar(artist, _s(item['name']))) return '';
      final xl  = _s(item['picture_xl']);
      final pic = xl.isNotEmpty ? xl : _s(item['picture_big']);
      // Deezer sends a grey placeholder when it has no real photo
      // (empty hash in the path). Treat it as "no image".
      if (pic.contains('/artist//') || pic.contains('d41d8cd98f00b204e9800998ecf8427e')) return '';
      return pic;
    } catch (_) { return ''; }
  }

  static Future<String?> _deezerAlbum(String album, String artist) async {
    try {
      final j = await _getJson('deezer',
          Uri.https('api.deezer.com', '/search/album', {'q': '$artist $album', 'limit': '1'}));
      if (j == null) return null;
      final items = _list(j, 'data');
      if (items.isEmpty) return '';
      final item = items.first as Map;
      if (!_similar(album, _s(item['title']))) return '';
      final cover = item['cover_xl'] ?? item['cover_big'];
      return _s(cover);
    } catch (_) { return ''; }
  }

  // Track search response embeds the parent album object with cover URLs.
  static Future<String?> _deezerTrack(String track, String artist) async {
    try {
      final j = await _getJson('deezer',
          Uri.https('api.deezer.com', '/search/track', {'q': '$artist $track', 'limit': '1'}));
      if (j == null) return null;
      final items = _list(j, 'data');
      if (items.isEmpty) return '';
      final item = items.first as Map;
      if (!_similar(track, _s(item['title']))) return '';
      final album = item['album'];
      if (album is! Map) return '';
      return _s(album['cover_xl'] ?? album['cover_big']);
    } catch (_) { return ''; }
  }

  static Future<String?> _audioDbAlbum(String album, String artist) async {
    try {
      final j = await _getJson('audiodb',
          Uri.https('www.theaudiodb.com', '/api/v1/json/123/searchalbum.php', {'s': artist, 'a': album}));
      if (j == null) return null;
      final albums = _list(j, 'album');
      if (albums.isEmpty) return '';
      final item = albums.first as Map;
      if (!_similar(album, _s(item['strAlbum']))) return '';
      return _s(item['strAlbumThumb']);
    } catch (_) { return ''; }
  }

  // Track-level art is rare on TheAudioDB (mostly filled for music videos),
  // best-effort only — empty result just falls through to the next source.
  static Future<String?> _audioDbTrack(String track, String artist) async {
    try {
      final j = await _getJson('audiodb',
          Uri.https('www.theaudiodb.com', '/api/v1/json/123/searchtrack.php', {'s': artist, 't': track}));
      if (j == null) return null;
      final tracks = _list(j, 'track');
      if (tracks.isEmpty) return '';
      final item = tracks.first as Map;
      if (!_similar(track, _s(item['strTrack']))) return '';
      return _s(item['strTrackThumb']);
    } catch (_) { return ''; }
  }

  // TheAudioDB — keyless public test key. No CORS support, so this only
  // works on native builds (skipped silently on web, caught by try/catch).
  static Future<String?> _audioDbArtist(String artist) async {
    try {
      final j = await _getJson('audiodb',
          Uri.https('www.theaudiodb.com', '/api/v1/json/123/search.php', {'s': artist}));
      if (j == null) return null;
      final artists = _list(j, 'artists');
      if (artists.isEmpty) return '';
      final a = artists.first as Map;
      if (!_similar(artist, _s(a['strArtist']))) return '';
      final thumb = _s(a['strArtistThumb']);
      return thumb.isNotEmpty ? thumb : _s(a['strArtistFanart']);
    } catch (_) { return ''; }
  }

  static const _mbHeaders = {'User-Agent': 'LastStats/2.0 (contact@laststats.app)'};

  // MusicBrainz curated "image" relation → resolved to a direct file URL via
  // Wikimedia Commons. Freely licensed and CORS-safe (works on web too).
  static Future<String?> _mbArtistImage(String artist) async {
    try {
      final search = await _getJson('musicbrainz',
          Uri.https('musicbrainz.org', '/ws/2/artist/', {
            'query': 'artist:"$artist"', 'limit': '1', 'fmt': 'json',
          }),
          headers: _mbHeaders);
      if (search == null) return null;
      final found = _list(search, 'artists');
      if (found.isEmpty) return '';
      final candidate = found.first as Map;
      if (!_similar(artist, _s(candidate['name']))) return '';
      final mbid = _s(candidate['id']);
      if (mbid.isEmpty) return '';

      final rel = await _getJson('musicbrainz',
          Uri.https('musicbrainz.org', '/ws/2/artist/$mbid', {'inc': 'url-rels', 'fmt': 'json'}),
          headers: _mbHeaders);
      if (rel == null) return null;
      final rels = _list(rel, 'relations');
      Map? imgRel;
      for (final r in rels) {
        if (r is Map && r['type'] == 'image') { imgRel = r; break; }
      }
      final pageUrl = _s(imgRel?['url']?['resource']);
      if (pageUrl.isEmpty) return '';

      // pageUrl is a Commons "File:" page — resolve to the actual image URL.
      final title = Uri.decodeFull(pageUrl.split('/wiki/').last);
      final file = await _getJson('wikimedia',
          Uri.https('commons.wikimedia.org', '/w/api.php', {
            'action': 'query', 'titles': title, 'prop': 'imageinfo',
            'iiprop': 'url', 'format': 'json', 'origin': '*',
          }));
      if (file == null) return null;
      final fq = file is Map ? file['query'] : null;
      final pages = fq is Map ? fq['pages'] : null;
      if (pages is Map) {
        for (final p in pages.values) {
          final info = (p is Map ? p['imageinfo'] : null);
          if (info is List && info.isNotEmpty) return _s((info.first as Map)['url']);
        }
      }
      return '';
    } catch (_) { return ''; }
  }

  // Wikipedia full-text search → page thumbnail. Broad coverage but the
  // riskiest source for false positives (a plain text search can land on a
  // totally unrelated page) — validated against the page title and, when
  // available, its short description before the thumbnail is trusted.
  static Future<String?> _wikipediaImage(String query, {required String expectName}) async {
    try {
      final j = await _getJson('wikimedia', Uri.https('en.wikipedia.org', '/w/api.php', {
        'action': 'query', 'generator': 'search', 'gsrsearch': query,
        'gsrlimit': '1', 'prop': 'pageimages|pageterms', 'piprop': 'thumbnail',
        'pithumbsize': '500', 'wbptterms': 'description',
        'format': 'json', 'origin': '*',
      }));
      if (j == null) return null;
      final jq = j is Map ? j['query'] : null;
      final pages = jq is Map ? jq['pages'] : null;
      if (pages is! Map) return '';
      for (final p in pages.values) {
        if (p is! Map) continue;
        final thumb = p['thumbnail']?['source'];
        if (thumb == null) continue;

        final title = _s(p['title']);
        if (!_similar(expectName, title)) continue; // page isn't about what we searched

        final descriptions = (p['terms']?['description'] as List?) ?? [];
        final description  = descriptions.isNotEmpty ? descriptions.first.toString().toLowerCase() : '';
        const musicHints = [
          'singer', 'musician', 'band', 'rapper', 'songwriter', 'composer',
          'dj', 'record producer', 'music group', 'vocalist', 'guitarist',
          'drummer', 'rock band', 'pop group', 'album', 'song by', 'music duo',
          'hip hop group', 'girl group', 'boy band', 'instrumentalist', 'orchestra',
        ];
        if (description.isNotEmpty && !musicHints.any(description.contains)) continue;

        return thumb.toString();
      }
      return '';
    } catch (_) { return ''; }
  }

  static Future<String?> _mbAlbum(String album, String artist) async {
    try {
      final search = await _getJson('musicbrainz',
          Uri.https('musicbrainz.org', '/ws/2/release/', {
            'query': 'release:"$album" AND artist:"$artist"',
            'limit': '1', 'fmt': 'json',
          }),
          headers: _mbHeaders);
      if (search == null) return null;
      final releases = _list(search, 'releases');
      if (releases.isEmpty) return '';
      final candidate = releases.first as Map;
      if (!_similar(album, _s(candidate['title']))) return '';
      final mbid = _s(candidate['id']);
      if (mbid.isEmpty) return '';

      // Only claim a cover when the Cover Art Archive really has one (a small
      // 250px request, instead of downloading the full-size image).
      final status = await _statusOf('coverart',
          Uri.https('coverartarchive.org', '/release/$mbid/front-250'));
      if (status == null) return null;
      if (status == 200) return 'https://coverartarchive.org/release/$mbid/front-500';
      return '';
    } catch (_) { return ''; }
  }

  static void debugLog(String msg) {
    assert(() { debugPrint(msg); return true; }());
  }
}

/// Small gray attribution label — "Source: iTunes" etc. — meant to sit at
/// the bottom of an artist/album/track sheet, under the artwork. Shows
/// nothing if the source isn't known yet (e.g. still resolving).
class ImageSourceLabel extends StatelessWidget {
  final String type; // 'artist' | 'album' | 'track'
  final String artist;
  final String album;
  final String track;
  const ImageSourceLabel({
    super.key,
    required this.type,
    required this.artist,
    this.album = '',
    this.track = '',
  });

  @override
  Widget build(BuildContext context) {
    final label = ImageService.sourceLabel(type, artist, album: album, track: track);
    if (label.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 11,
            ),
      ),
    );
  }
}

void unawaited(Future<void> f) => f.ignore();