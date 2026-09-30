// Optional "clean library" layer: links different versions of the same
// track / album / artist into one entry (plays are summed) and splits
// collaboration credits ("A & B", "A feat. B") into their real artists.
//
// Two independent options (both off by default, see app_state.dart):
//   • mergeVersionsNotifier — link versions: "Song (Remastered 2011)",
//     "Song - Single Version", "Song (feat. X)", "Album (Deluxe Edition)"...
//   • splitCollabsNotifier  — a "Gims & Damso" artist entry is credited to
//     Gims AND Damso instead of being a third, separate artist.
//
// Safety rules, so unrelated items never get mixed:
//   • Tracks/albums are only linked when the cleaned title AND the primary
//     artist are identical.
//   • Bracket/dash suffixes that mean a *different* recording (remix,
//     instrumental, acoustic, live, sped up, part 2...) are kept.
//   • "feat." / "ft." / "featuring" always split. Ambiguous separators
//     (&, comma, x, +, and, vs) split only when one side is an artist the
//     user really has in their library, so "Simon & Garfunkel" or
//     "Earth, Wind & Fire" stay whole.
import 'package:shared_preferences/shared_preferences.dart';
import '../app_state.dart';
import 'data_cache.dart';
import 'friends_library_service.dart';
import 'lastfm_service.dart';

class LibraryMerge {
  LibraryMerge._();

  static bool get mergeOn => mergeVersionsNotifier.value;
  static bool get splitOn => splitCollabsNotifier.value;
  static bool get active  => mergeOn || splitOn;

  // ── Text normalisation ─────────────────────────────────────────────────
  static const _from = 'àáâãäåāçćčèéêëēěìíîïīñńòóôõöøōùúûüūýÿžśšß';
  static const _to   = 'aaaaaaaccceeeeeeiiiiinnooooooouuuuuyyzssss';

  static String fold(String s) {
    var t = s.toLowerCase();
    for (var i = 0; i < _from.length; i++) {
      t = t.replaceAll(_from[i], _to[i]);
    }
    return t;
  }

  static final _nonAlnum = RegExp(r'[^\p{L}\p{N}]', unicode: true);
  static String alnum(String s) => fold(s).replaceAll(_nonAlnum, '');

  // ── Title cleaning ─────────────────────────────────────────────────────
  static final _bracket = RegExp(r'\s*[\(\[\{]([^\)\]\}]*)[\)\]\}]');
  static final _dashTail = RegExp(r'\s[-–—]\s([^-–—]+)$');
  static final _featTail = RegExp(
      r'\s+(feat\.?|ft\.?|featuring)\s+.+$', caseSensitive: false);

  static final _trackNoise = RegExp(
      r'remaster|version|edit|mono|stereo|deluxe|bonus|explicit|clean|single|'
      r'album|radio|feat|ft\.|featuring|with |from |original|official|lyric|'
      r'video|audio|expanded|anniversary|re-?record|taylor|soundtrack|ost|'
      r'theme|anthem|edition',
      caseSensitive: false);
  // A suffix that means a genuinely different recording: never stripped.
  static final _trackDistinct = RegExp(
      r'remix|rmx|mix|instrumental|acoustic|cover|demo|karaoke|sped|slowed|'
      r'reverb|nightcore|vip|flip|bootleg|mashup|cappella|interlude|skit|live|'
      r'unplugged|session|\bpt\b|part|vol|\bno\.?\s*\d|\bii+\b',
      caseSensitive: false);
  static final _albumNoise = RegExp(
      r'deluxe|edition|remaster|expanded|anniversary|bonus|explicit|clean|'
      r'version|extended|special|collector|standard|international|japan|'
      r'single|re-?issue|re-?release',
      caseSensitive: false);

  // Bracket content is dropped unless it names a different recording.
  // Explicit "noise" words (remaster, radio edit, feat...) always win, so
  // "(2011 Remaster)" goes; arbitrary text like "(League of Legends
  // Worlds Anthem)" also goes; "(Remix)", "(Live)", "(Part 2)" stay.
  static final _alwaysNoise = RegExp(
      r'remaster|radio edit|single version|album version|feat|ft\.|featuring',
      caseSensitive: false);
  static bool _stripTrack(String c) =>
      _alwaysNoise.hasMatch(c) || !_trackDistinct.hasMatch(c);

  static String cleanTrack(String title) {
    var t = title.trim();
    t = t.replaceAllMapped(_bracket, (m) => _stripTrack(m.group(1) ?? '') ? '' : m.group(0)!);
    final d = _dashTail.firstMatch(t);
    if (d != null) {
      final c = d.group(1) ?? '';
      if (_trackNoise.hasMatch(c) && !_trackDistinct.hasMatch(c)) t = t.substring(0, d.start);
    }
    t = t.replaceAll(_featTail, '');
    t = t.trim();
    return t.isEmpty ? title.trim() : t;
  }

  static String cleanAlbum(String title) {
    var t = title.trim();
    t = t.replaceAllMapped(_bracket,
        (m) => _albumNoise.hasMatch(m.group(1) ?? '') ? '' : m.group(0)!);
    final d = _dashTail.firstMatch(t);
    if (d != null && _albumNoise.hasMatch(d.group(1) ?? '')) {
      t = t.substring(0, d.start);
    }
    t = t.trim();
    return t.isEmpty ? title.trim() : t;
  }

  // ── Artist credits ─────────────────────────────────────────────────────
  static final _featSplit = RegExp(
      r'\s*[\(\[]?\s*\b(?:feat\.?|ft\.?|featuring)\b\.?\s*', caseSensitive: false);
  static final _ambiguousSplit = RegExp(
      r'\s*,\s*|\s+&\s+|\s+x\s+|\s+\+\s+|\s+and\s+|\s+vs\.?\s+',
      caseSensitive: false);

  static String artistKey(String name) {
    var k = alnum(name);
    if (k.startsWith('the') && k.length > 6) k = k.substring(3);
    return k;
  }

  /// Individual artists behind a credit. [known] = artist keys the user
  /// really has in their library (used for the ambiguous separators).
  static List<String> artistParts(String name, Set<String> known,
      {required bool ambiguous}) {
    final pieces = name
        .split(_featSplit)
        .map((p) => p.replaceAll(RegExp(r'[\)\]]+\s*$'), '').trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final out = <String>[];
    for (final piece in pieces.isEmpty ? [name.trim()] : pieces) {
      if (ambiguous && known.isNotEmpty) {
        final sub = piece.split(_ambiguousSplit)
            .map((p) => p.trim()).where((p) => p.length >= 2).toList();
        if (sub.length > 1 &&
            sub.any((p) => known.contains(artistKey(p)) &&
                artistKey(p) != artistKey(piece))) {
          out.addAll(sub);
          continue;
        }
      }
      out.add(piece);
    }
    // De-duplicate while keeping the order.
    final seen = <String>{};
    return out.where((p) => seen.add(artistKey(p))).toList();
  }

  static String primaryArtist(String name, Set<String> known) {
    final p = artistParts(name, known, ambiguous: splitOn);
    return p.isEmpty ? name : p.first;
  }

  static String trackKey(String title, String artist, Set<String> known) =>
      '${alnum(cleanTrack(title))}|${artistKey(primaryArtist(artist, known))}';

  static String albumKey(String title, String artist, Set<String> known) =>
      '${alnum(cleanAlbum(title))}|${artistKey(primaryArtist(artist, known))}';

  /// True when two items are the same thing under the active options.
  static bool same(String type, String n1, String a1, String n2, String a2,
      Set<String> known) {
    switch (type) {
      case 'artists': return artistKey(n1) == artistKey(n2);
      case 'albums':  return albumKey(n1, a1, known) == albumKey(n2, a2, known);
      default:        return trackKey(n1, a1, known) == trackKey(n2, a2, known);
    }
  }

  // ── Comparison keys (taste compare): legacy lower-case keys when both
  // options are off, normalised keys when active, so "my" side (local
  // scrobbles) and "their" side (API lists) always use the same form.
  static Set<String> get _allKnown =>
      _known.values.fold<Set<String>>(<String>{}, (a, b) => a..addAll(b));

  static String ckArtist(String name) => !active
      ? name.toLowerCase()
      : artistKey(primaryArtist(name, _allKnown));

  static String ckTitle(String title, {bool album = false}) => !mergeOn
      ? title.toLowerCase()
      : alnum(album ? cleanAlbum(title) : cleanTrack(title));

  // ── Known artists (per Last.fm user) ───────────────────────────────────
  static final Map<String, Set<String>> _known = {};
  static Set<String> knownSync(String user) =>
      _known[user.toLowerCase()] ?? const <String>{};

  static Future<Set<String>> ensureKnown(LastFmService s, String? user) async {
    final u = (user ?? s.username).toLowerCase();
    final have = _known[u];
    if (have != null) return have;
    try {
      final raw = await s.rawTopArtists(period: 'overall', limit: 500, user: user);
      return _known[u] = raw
          .map((e) => artistKey((e['name'] ?? '').toString()))
          .where((k) => k.isNotEmpty)
          .toSet();
    } catch (_) {
      return const <String>{};
    }
  }

  // ── API lists ──────────────────────────────────────────────────────────
  static final Map<String, ({DateTime at, List<dynamic> list})> _cache = {};
  static const _ttl = Duration(minutes: 3);

  /// Merged/split version of a user's top list, sliced like the plain API.
  static Future<List<dynamic>> topList(
    LastFmService s, {
    required String type,
    required String period,
    required int limit,
    required int page,
    String? user,
  }) async {
    final u   = (user ?? s.username).toLowerCase();
    final key = '$u|$type|$period|$mergeOn|$splitOn';
    var hit = _cache[key];
    if (hit == null || DateTime.now().difference(hit.at) > _ttl) {
      final known = await ensureKnown(s, user);
      Future<List<dynamic>> raw(int p) => switch (type) {
        'artists' => s.rawTopArtists(period: period, limit: 200, page: p, user: user),
        'albums'  => s.rawTopAlbums( period: period, limit: 200, page: p, user: user),
        _         => s.rawTopTracks( period: period, limit: 200, page: p, user: user),
      };
      // Up to 3 raw pages (600 entries) so big requests such as the taste
      // profile's top 500 are still served after merging.
      final all = <dynamic>[];
      for (var p = 1; p <= 3; p++) {
        final chunk = await raw(p);
        all.addAll(chunk);
        if (chunk.length < 200) break;
      }
      hit = (at: DateTime.now(), list: process(type, all, known));
      _cache[key] = hit;
    }
    final from = (page - 1) * limit;
    if (from >= hit.list.length) return [];
    return hit.list.sublist(from, (from + limit).clamp(0, hit.list.length));
  }

  static int _plays(dynamic e) =>
      int.tryParse((e['playcount'] ?? '0').toString()) ?? 0;

  static String _artistNameOf(dynamic e) {
    final a = e['artist'];
    if (a is Map) return (a['name'] ?? a['#text'] ?? '').toString();
    return (a ?? '').toString();
  }

  static List<dynamic> process(String type, List<dynamic> raw, Set<String> known) {
    // key -> [items]; insertion order keeps ties stable.
    final groups = <String, List<Map<String, dynamic>>>{};
    void put(String key, Map<String, dynamic> item) =>
        groups.putIfAbsent(key, () => []).add(item);

    for (final e in raw) {
      final item = Map<String, dynamic>.from(e as Map);
      final name = (item['name'] ?? '').toString();
      if (type == 'artists') {
        final parts = splitOn
            ? artistParts(name, known, ambiguous: true)
            : [name];
        if (parts.length <= 1) {
          put(mergeOn || splitOn ? artistKey(name) : name, item);
        } else {
          for (final part in parts) {
            put(artistKey(part), {
              'name': part,
              'playcount': '${_plays(item)}',
              'image': <dynamic>[],
              'url': '',
              'ls_split': true,
            });
          }
        }
      } else if (type == 'albums') {
        put(mergeOn ? albumKey(name, _artistNameOf(item), known) : '$name|${_artistNameOf(item)}', item);
      } else {
        put(mergeOn ? trackKey(name, _artistNameOf(item), known) : '$name|${_artistNameOf(item)}', item);
      }
    }

    final merged = <Map<String, dynamic>>[];
    for (final g in groups.values) {
      // Prefer a real library entry (with image / url) over a synthetic part.
      final real = g.where((x) => x['ls_split'] != true).toList();
      final base = Map<String, dynamic>.from(
          (real.isNotEmpty ? real : g).reduce((a, b) => _plays(b) > _plays(a) ? b : a));
      base['playcount'] = '${g.fold<int>(0, (t, x) => t + _plays(x))}';
      if (g.length > 1) base['ls_merged'] = g.length;
      base.remove('ls_split');
      merged.add(base);
    }
    merged.sort((a, b) => _plays(b).compareTo(_plays(a)));
    for (var i = 0; i < merged.length; i++) {
      final at = merged[i]['@attr'];
      merged[i]['@attr'] = {...(at is Map ? Map<String, dynamic>.from(at) : {}), 'rank': '${i + 1}'};
    }
    return merged;
  }

  // ── Option changes ─────────────────────────────────────────────────────
  static Future<void> setMerge(bool v) async {
    mergeVersionsNotifier.value = v;
    (await SharedPreferences.getInstance()).setBool('ls_merge_versions', v);
    await _changed();
  }

  static Future<void> setSplit(bool v) async {
    splitCollabsNotifier.value = v;
    (await SharedPreferences.getInstance()).setBool('ls_split_collabs', v);
    await _changed();
  }

  static Future<void> _changed() async {
    _cache.clear();
    // Cached friend libraries were built with the previous setting.
    await FriendsLibraryService.clearAll();
    for (final p in const ['7day', '1month', '3month', '6month', '12month', 'overall']) {
      await DataCache.invalidate(DataCache.keyTopArtists(p));
      await DataCache.invalidate(DataCache.keyTopAlbums(p));
      await DataCache.invalidate(DataCache.keyTopTracks(p));
    }
  }
}

/// Counts local scrobbles under the active merge/split options.
class LocalTally {
  final Set<String> known;
  LocalTally(this.known);

  final _count   = <String, int>{};
  final _names   = <String, Map<String, int>>{};
  final _artists = <String, Map<String, int>>{};

  void _add(String key, String name, String artist) {
    _count[key] = (_count[key] ?? 0) + 1;
    (_names[key]   ??= {})[name]   = ((_names[key]![name])     ?? 0) + 1;
    if (artist.isNotEmpty) {
      (_artists[key] ??= {})[artist] = ((_artists[key]![artist]) ?? 0) + 1;
    }
  }

  /// [type] = 'artists' | 'albums' | 'tracks'
  void addScrobble(String type, {required String name, required String artist}) {
    if (type == 'artists') {
      final parts = LibraryMerge.splitOn
          ? LibraryMerge.artistParts(name, known, ambiguous: true)
          : [name];
      for (final p in parts) {
        if (p.isEmpty) continue;
        final key = LibraryMerge.active ? LibraryMerge.artistKey(p) : p;
        _add(key, p, '');
      }
      return;
    }
    if (name.isEmpty) return;
    final key = !LibraryMerge.mergeOn
        ? '$name|||$artist'
        : (type == 'albums'
            ? LibraryMerge.albumKey(name, artist, known)
            : LibraryMerge.trackKey(name, artist, known));
    _add(key, name, artist);
  }

  String _best(Map<String, int>? m) => m == null || m.isEmpty
      ? ''
      : m.entries.reduce((a, b) => b.value > a.value ? b : a).key;

  List<({String name, String artist, int plays})> sorted() {
    final list = _count.entries.map((e) => (
          name: _best(_names[e.key]),
          artist: _best(_artists[e.key]),
          plays: e.value,
        )).toList()
      ..sort((a, b) => b.plays.compareTo(a.plays));
    return list;
  }
}
