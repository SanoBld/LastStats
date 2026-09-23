// lib/services/taste_engine.dart
// ══════════════════════════════════════════════════════════════════════════
//  Personal recommendation engine for the dashboard "For you" group.
//
//  Last.fm has no usable "recommended for you" endpoint, so this builds its
//  own taste profile from YOUR listening data and scores candidates itself:
//
//   1. Profile   → artist weights blended from all-time (40%), last 3
//                  months (40%) and last month (20%) play shares, plus a
//                  small bonus for every loved track. Everything you have
//                  already played (top artists / tracks / albums) is kept
//                  as an "already known" set so it is never recommended.
//   2. Similar   → each seed artist's similar artists are fetched; a
//                  candidate's score is  Σ seedWeight × matchScore  and is
//                  boosted when several of your seeds point to it.
//   3. Sources   → foryou / fresh / genre / deeper / forgotten / albums,
//                  each one a different view of the same profile.
//
//  All network calls are wrapped: a failing call only shrinks the result,
//  it never throws out of a public method.
// ══════════════════════════════════════════════════════════════════════════

import 'lastfm_service.dart';

class TasteRec {
  final String name;
  final String artist;        // empty for artist entries
  final String type;          // 'artists' | 'tracks' | 'albums'
  final dynamic image;        // raw Last.fm image list (may be null)
  final int playcount;        // your own plays when meaningful, else 0
  final List<String> reasons; // seed artists that led to this pick
  final String tag;           // genre tag for the "genre" source
  const TasteRec({
    required this.name,
    required this.type,
    this.artist = '',
    this.image,
    this.playcount = 0,
    this.reasons = const [],
    this.tag = '',
  });
}

class _Profile {
  final Map<String, double> weights = {};   // artist (lowercase) -> weight
  final Map<String, double> recent  = {};   // artist (lowercase) -> last-month share
  final Map<String, String> display = {};   // artist (lowercase) -> display name
  final Set<String> knownArtists = {};
  final Set<String> knownTracks  = {};      // 'artist|track' (lowercase)
  final Set<String> knownAlbums  = {};      // 'artist|album' (lowercase)
  final Set<String> recentTracks = {};      // last 3 months
  List<dynamic> topTracks = [];             // all-time, ordered

  List<MapEntry<String, double>> seeds(int n, {Map<String, double>? from}) {
    final e = (from ?? weights).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return e.take(n).toList();
  }
}

class _Cand {
  String name = '';
  dynamic image;
  double score = 0;
  int hits = 0;
  final List<MapEntry<String, double>> reasons = [];
}

class TasteEngine {
  final LastFmService s;
  TasteEngine(this.s);

  // ── Session caches (shared by every tab of the group) ───────────────────
  static _Profile? _profile;
  static String _profileUser = '';
  static DateTime? _profileAt;
  static Future<_Profile>? _building;
  static final Map<String, (DateTime, List<dynamic>)> _simCache = {};
  static final Map<String, (DateTime, List<dynamic>)> _tagCache = {};
  static (DateTime, List<TasteRec>)? _foryouCache;

  static const _ttl = Duration(minutes: 30);

  // ── Helpers ─────────────────────────────────────────────────────────────
  static String _n(Object? v) => (v ?? '').toString().toLowerCase().trim();
  static int _pc(Map m) => int.tryParse((m['playcount'] ?? '0').toString()) ?? 0;
  static String _artistOf(Map m) {
    final a = m['artist'];
    return a is Map ? (a['name'] ?? a['#text'] ?? '').toString() : (a ?? '').toString();
  }

  static Future<T> _safe<T>(Future<T> f, T fallback) async {
    try { return await f; } catch (_) { return fallback; }
  }

  // Runs [fn] over [items] a few at a time (Last.fm rate limits bursts).
  static Future<List<R>> _pool<T, R>(List<T> items, Future<R> Function(T) fn,
      {int size = 4}) async {
    final out = <R>[];
    for (var i = 0; i < items.length; i += size) {
      out.addAll(await Future.wait(items.skip(i).take(size).map(fn)));
    }
    return out;
  }

  static Map<String, double> _shares(List<dynamic> list) {
    final maps = list.whereType<Map>().toList();
    final total = maps.fold<int>(0, (a, m) => a + _pc(m));
    final out = <String, double>{};
    for (var i = 0; i < maps.length; i++) {
      final k = _n(maps[i]['name']);
      if (k.isEmpty) continue;
      // Fall back to a rank-based share if play counts are missing.
      out[k] = total > 0 ? _pc(maps[i]) / total : 1 / (i + 2);
    }
    return out;
  }

  // ── 1. Profile ──────────────────────────────────────────────────────────
  Future<_Profile> _getProfile() async {
    final fresh = _profile != null &&
        _profileUser == s.username &&
        _profileAt != null &&
        DateTime.now().difference(_profileAt!) < _ttl;
    if (fresh) return _profile!;
    if (_building != null && _profileUser == s.username) return _building!;
    _profileUser = s.username;
    _building = _buildProfile().whenComplete(() => _building = null);
    return _building!;
  }

  Future<_Profile> _buildProfile() async {
    final r = await Future.wait<List<dynamic>>([
      _safe(s.getTopArtists(period: 'overall', limit: 500), <dynamic>[]),
      _safe(s.getTopArtists(period: '3month',  limit: 50),  <dynamic>[]),
      _safe(s.getTopArtists(period: '1month',  limit: 30),  <dynamic>[]),
      _safe(s.getTopTracks(period: 'overall', limit: 500),  <dynamic>[]),
      _safe(s.getTopTracks(period: '3month',  limit: 200),  <dynamic>[]),
      _safe(s.getTopAlbums(period: 'overall', limit: 300),  <dynamic>[]),
      _safe(s.getLovedTracks(limit: 200),                   <dynamic>[]),
    ]);
    final p = _Profile();

    for (final a in r[0].whereType<Map>()) {
      final k = _n(a['name']);
      if (k.isEmpty) continue;
      p.knownArtists.add(k);
      p.display[k] = a['name'].toString();
    }
    for (final a in [...r[1], ...r[2]].whereType<Map>()) {
      final k = _n(a['name']);
      if (k.isEmpty) continue;
      p.knownArtists.add(k);
      p.display.putIfAbsent(k, () => a['name'].toString());
    }

    final all = _shares(r[0]), m3 = _shares(r[1]), m1 = _shares(r[2]);
    for (final k in {...all.keys, ...m3.keys, ...m1.keys}) {
      p.weights[k] = 0.4 * (all[k] ?? 0) + 0.4 * (m3[k] ?? 0) + 0.2 * (m1[k] ?? 0);
    }
    p.recent.addAll(m1.isNotEmpty ? m1 : m3);

    // Loved tracks: every love nudges the artist up.
    for (final t in r[6].whereType<Map>()) {
      final k = _n(_artistOf(t));
      if (k.isEmpty) continue;
      p.weights[k] = (p.weights[k] ?? 0) + 0.01;
      p.display.putIfAbsent(k, () => _artistOf(t));
      p.knownArtists.add(k);
    }

    p.topTracks = r[3];
    for (final t in r[3].whereType<Map>()) {
      p.knownTracks.add('${_n(_artistOf(t))}|${_n(t['name'])}');
    }
    for (final t in r[4].whereType<Map>()) {
      p.recentTracks.add('${_n(_artistOf(t))}|${_n(t['name'])}');
    }
    for (final t in r[6].whereType<Map>()) {
      p.knownTracks.add('${_n(_artistOf(t))}|${_n(t['name'])}');
    }
    for (final a in r[5].whereType<Map>()) {
      p.knownAlbums.add('${_n(_artistOf(a))}|${_n(a['name'])}');
    }

    _profile   = p;
    _profileAt = DateTime.now();
    return p;
  }

  Future<List<dynamic>> _similar(String artist) async {
    final hit = _simCache[artist];
    if (hit != null && DateTime.now().difference(hit.$1) < _ttl) return hit.$2;
    final l = await _safe(s.getSimilarArtists(artist, limit: 40), <dynamic>[]);
    if (l.isNotEmpty) _simCache[artist] = (DateTime.now(), l);
    return l;
  }

  Future<List<dynamic>> _tags(String artist) async {
    final hit = _tagCache[artist];
    if (hit != null && DateTime.now().difference(hit.$1) < _ttl) return hit.$2;
    final l = await _safe(s.getArtistTopTags(artist), <dynamic>[]);
    if (l.isNotEmpty) _tagCache[artist] = (DateTime.now(), l);
    return l;
  }

  // ── 2. Similar-artist scoring (shared by foryou / fresh / albums) ───────
  Future<List<TasteRec>> _recommend(_Profile p,
      List<MapEntry<String, double>> seeds, int limit) async {
    if (seeds.isEmpty) return [];
    final sims = await _pool<MapEntry<String, double>, List<dynamic>>(
        seeds, (e) => _similar(p.display[e.key] ?? e.key));
    final seedKeys = seeds.map((e) => e.key).toSet();
    final cands = <String, _Cand>{};

    for (var i = 0; i < seeds.length; i++) {
      final w = seeds[i].value;
      final seedName = p.display[seeds[i].key] ?? seeds[i].key;
      for (final m in sims[i].whereType<Map>()) {
        final name = (m['name'] ?? '').toString();
        final k = _n(name);
        if (k.isEmpty || p.knownArtists.contains(k) || seedKeys.contains(k)) continue;
        final match = double.tryParse((m['match'] ?? '0').toString()) ?? 0;
        final c = cands.putIfAbsent(k, () => _Cand());
        c.name = name;
        c.image ??= m['image'];
        c.score += w * match;
        c.hits++;
        c.reasons.add(MapEntry(seedName, w * match));
      }
    }

    final ranked = cands.values.toList()
      ..sort((a, b) => (b.score * (1 + 0.35 * (b.hits - 1)))
          .compareTo(a.score * (1 + 0.35 * (a.hits - 1))));
    return ranked.take(limit).map((c) {
      c.reasons.sort((a, b) => b.value.compareTo(a.value));
      return TasteRec(
        name: c.name,
        type: 'artists',
        image: c.image,
        reasons: c.reasons.take(2).map((e) => e.key).toList(),
      );
    }).toList();
  }

  // ── 3. Sources ──────────────────────────────────────────────────────────

  /// Artists close to what you play the most (all-time + recent blend).
  Future<List<TasteRec>> forYou({int limit = 24}) async {
    final c = _foryouCache;
    if (c != null && DateTime.now().difference(c.$1) < _ttl && c.$2.length >= limit) {
      return c.$2.take(limit).toList();
    }
    final p = await _getProfile();
    final out = await _recommend(p, p.seeds(10), 40);
    if (out.isNotEmpty) _foryouCache = (DateTime.now(), out);
    return out.take(limit).toList();
  }

  /// Same idea, but seeded only by what you played in the last month.
  Future<List<TasteRec>> fresh({int limit = 24}) async {
    final p = await _getProfile();
    return _recommend(p, p.seeds(6, from: p.recent), limit);
  }

  static final _badTag = RegExp(r'^(\d{4}s?|\d0s)$');
  static const _genericTags = {
    'seen live', 'favorites', 'favourites', 'favorite', 'favourite', 'all',
    'albums i own', 'my music', 'love', 'loved', 'awesome', 'good', 'beautiful',
    'male vocalists', 'female vocalists', 'under 2000 listeners', 'usa', 'uk',
    'american', 'british', 'french', 'german', 'japanese', 'canadian',
    'singer-songwriter', 'cool', 'best', 'amazing', 'epic', 'classic',
  };

  /// Popular tracks in the genres you listen to, from artists you don't know.
  Future<List<TasteRec>> genre({int limit = 24}) async {
    final p = await _getProfile();
    final seeds = p.seeds(8);
    final tagLists = await _pool<MapEntry<String, double>, List<dynamic>>(
        seeds, (e) => _tags(p.display[e.key] ?? e.key));

    final score = <String, double>{};
    for (var i = 0; i < seeds.length; i++) {
      for (final t in tagLists[i].whereType<Map>()) {
        final name = _n(t['name']);
        final count = int.tryParse((t['count'] ?? '0').toString()) ?? 0;
        if (name.isEmpty || count < 20 || _genericTags.contains(name) ||
            _badTag.hasMatch(name) || p.knownArtists.contains(name)) continue;
        score[name] = (score[name] ?? 0) + seeds[i].value * count / 100;
      }
    }
    final top = (score.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(3).map((e) => e.key).toList();
    if (top.isEmpty) return [];

    final lists = await _pool<String, List<dynamic>>(
        top, (t) => _safe(s.getTagTopTracks(t, limit: 30), <dynamic>[]));

    // Round-robin between the tags so the tab is a real mix.
    final out = <TasteRec>[];
    final seen = <String>{};
    for (var i = 0; out.length < limit; i++) {
      var any = false;
      for (var j = 0; j < lists.length; j++) {
        if (i >= lists[j].length) continue;
        any = true;
        final m = lists[j][i];
        if (m is! Map) continue;
        final artist = _artistOf(m);
        final key = '${_n(artist)}|${_n(m['name'])}';
        if (p.knownArtists.contains(_n(artist)) || !seen.add(key)) continue;
        out.add(TasteRec(
            name: (m['name'] ?? '').toString(), artist: artist, type: 'tracks',
            image: m['image'], tag: top[j]));
        if (out.length >= limit) break;
      }
      if (!any) break;
    }
    return out;
  }

  /// Tracks by your favorite artists that you have (almost) never played.
  Future<List<TasteRec>> deeperCuts({int limit = 24}) async {
    final p = await _getProfile();
    final seeds = p.seeds(6);
    final lists = await _pool<MapEntry<String, double>, List<dynamic>>(seeds,
        (e) => _safe(s.getArtistTopTracks(p.display[e.key] ?? e.key, limit: 40), <dynamic>[]));

    final cands = <(double, TasteRec)>[];
    for (var i = 0; i < seeds.length; i++) {
      final artist = p.display[seeds[i].key] ?? seeds[i].key;
      var taken = 0;
      for (var r = 0; r < lists[i].length && taken < 5; r++) {
        final m = lists[i][r];
        if (m is! Map) continue;
        final name = (m['name'] ?? '').toString();
        if (name.isEmpty || p.knownTracks.contains('${_n(artist)}|${_n(name)}')) continue;
        taken++;
        cands.add((
          seeds[i].value / (1 + r / 8),
          TasteRec(name: name, artist: artist, type: 'tracks', image: m['image']),
        ));
      }
    }
    cands.sort((a, b) => b.$1.compareTo(a.$1));
    return cands.take(limit).map((e) => e.$2).toList();
  }

  /// Your all-time favorites that dropped out of your last 3 months.
  Future<List<TasteRec>> forgotten({int limit = 24}) async {
    final p = await _getProfile();
    final out = <TasteRec>[];
    for (final t in p.topTracks.whereType<Map>()) {
      final artist = _artistOf(t);
      final key = '${_n(artist)}|${_n(t['name'])}';
      if (p.recentTracks.contains(key) || _pc(t) < 3) continue;
      out.add(TasteRec(
          name: (t['name'] ?? '').toString(), artist: artist, type: 'tracks',
          image: t['image'], playcount: _pc(t)));
      if (out.length >= limit) break;
    }
    return out;
  }

  /// Best albums of the artists the engine recommends, minus albums you own.
  Future<List<TasteRec>> albums({int limit = 24}) async {
    final p = await _getProfile();
    final recs = (await forYou(limit: 12)).take(10).toList();
    final lists = await _pool<TasteRec, List<dynamic>>(
        recs, (r) => s.getArtistTopAlbums(r.name, limit: 4));

    final out = <TasteRec>[];
    for (var i = 0; out.length < limit; i++) {
      var any = false;
      for (var j = 0; j < recs.length; j++) {
        if (i >= lists[j].length) continue;
        any = true;
        final m = lists[j][i];
        if (m is! Map) continue;
        final name = (m['name'] ?? '').toString();
        if (name.isEmpty || name == '(null)' ||
            p.knownAlbums.contains('${_n(recs[j].name)}|${_n(name)}')) continue;
        out.add(TasteRec(
            name: name, artist: recs[j].name, type: 'albums',
            image: m['image'], reasons: recs[j].reasons));
        if (out.length >= limit) break;
      }
      if (!any || i >= 3) break;
    }
    return out;
  }
}
