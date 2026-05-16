import 'dart:convert';
import 'package:http/http.dart' as http;

/// Équivalent de l'objet API + Cache de script.js
class LastFmService {
  static const _baseUrl  = 'https://ws.audioscrobbler.com/2.0/';
  static const _cacheTtl = Duration(minutes: 30);

  final String apiKey;
  final String username;

  // Cache en mémoire (clé → {data, timestamp})
  final Map<String, _CacheEntry> _cache = {};

  LastFmService({required this.apiKey, required this.username});

  // ─────────────────────────────────────────────────────────
  // Interne : construit l'URL et fait l'appel HTTP avec retry
  // ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _fetch(
    String method, {
    Map<String, String> params = const {},
    int retries = 3,
  }) async {
    final queryParams = {
      'method':  method,
      'api_key': apiKey,
      'user':    username,
      'format':  'json',
      ...params,
    };

    final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        final response = await http
            .get(uri)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data.containsKey('error')) {
          throw Exception(data['message'] ?? 'API error ${data['error']}');
        }

        return data;
      } catch (e) {
        if (attempt == retries - 1) rethrow;
        await Future.delayed(Duration(milliseconds: 800 * (attempt + 1)));
      }
    }

    throw Exception('Impossible de joindre Last.fm.');
  }

  // ─────────────────────────────────────────────────────────
  // Avec cache (équivalent de API.call dans script.js)
  // ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _call(
    String method, {
    Map<String, String> params = const {},
    bool skipCache = false,
  }) async {
    final cacheKey = '${username}_${method}_${jsonEncode(params)}';

    if (!skipCache) {
      final entry = _cache[cacheKey];
      if (entry != null &&
          DateTime.now().difference(entry.timestamp) < _cacheTtl) {
        return entry.data;
      }
    }

    final data = await _fetch(method, params: params);
    _cache[cacheKey] = _CacheEntry(data);
    return data;
  }

  /// Vide le cache en mémoire
  void clearCache() => _cache.clear();

  // ─────────────────────────────────────────────────────────
  // API publique
  // ─────────────────────────────────────────────────────────

  /// user.getInfo — infos du profil (avatar, scrobbles totaux, date inscription…)
  Future<Map<String, dynamic>?> getUserInfo() async {
    final data = await _call('user.getInfo');
    return data['user'] as Map<String, dynamic>?;
  }

  /// user.getTopArtists
  /// [period] : '7day' | '1month' | '3month' | '6month' | '12month' | 'overall'
  Future<List<dynamic>> getTopArtists({
    String period = 'overall',
    int limit = 50,
    int page = 1,
  }) async {
    final data = await _call(
      'user.getTopArtists',
      params: {
        'period': period,
        'limit':  limit.toString(),
        'page':   page.toString(),
      },
    );
    final raw = data['topartists']?['artist'];
    if (raw == null) return [];
    return raw is List ? raw : [raw];
  }

  /// user.getTopAlbums
  Future<List<dynamic>> getTopAlbums({
    String period = 'overall',
    int limit = 50,
    int page = 1,
  }) async {
    final data = await _call(
      'user.getTopAlbums',
      params: {
        'period': period,
        'limit':  limit.toString(),
        'page':   page.toString(),
      },
    );
    final raw = data['topalbums']?['album'];
    if (raw == null) return [];
    return raw is List ? raw : [raw];
  }

  /// user.getTopTracks
  Future<List<dynamic>> getTopTracks({
    String period = 'overall',
    int limit = 50,
    int page = 1,
  }) async {
    final data = await _call(
      'user.getTopTracks',
      params: {
        'period': period,
        'limit':  limit.toString(),
        'page':   page.toString(),
      },
    );
    final raw = data['toptracks']?['track'];
    if (raw == null) return [];
    return raw is List ? raw : [raw];
  }

  /// user.getRecentTracks — dernières écoutes
  Future<Map<String, dynamic>> getRecentTracks({
    int limit = 50,
    int page = 1,
    int? from, // Unix timestamp
    int? to,   // Unix timestamp
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'page':  page.toString(),
    };
    if (from != null) params['from'] = from.toString();
    if (to   != null) params['to']   = to.toString();

    final data = await _call('user.getRecentTracks', params: params);
    return data['recenttracks'] as Map<String, dynamic>? ?? {};
  }

  /// Nombre de scrobbles sur un mois donné (équivalent de API.getMonthScrobbles)
  Future<int> getMonthScrobbles(int year, int month) async {
    final from = DateTime(year, month, 1)
        .millisecondsSinceEpoch ~/ 1000;
    final to = DateTime(year, month + 1, 0, 23, 59, 59)
        .millisecondsSinceEpoch ~/ 1000;

    try {
      final data = await _call(
        'user.getRecentTracks',
        params: {
          'from':  from.toString(),
          'to':    to.toString(),
          'limit': '1',
        },
      );
      final total = data['recenttracks']?['@attr']?['total'];
      return int.tryParse(total?.toString() ?? '0') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// user.getWeeklyChartList — liste des semaines disponibles
  Future<List<dynamic>> getWeeklyChartList() async {
    final data = await _call('user.getWeeklyChartList');
    final raw = data['weeklychartlist']?['chart'];
    if (raw == null) return [];
    return raw is List ? raw : [raw];
  }
}

// ─────────────────────────────────────────────────────────
// Classe interne pour le cache
// ─────────────────────────────────────────────────────────
class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();
}
