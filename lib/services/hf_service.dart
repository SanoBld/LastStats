// lib/services/hf_service.dart
// Hugging Face client: search GGUF models, list the files of a repo and
// build download URLs. Talks only to the endpoint set in app_state.dart.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;

import '../app_state.dart';
import '../models/model_models.dart';

/// [kind]: 'offline' | 'auth' | 'notFound' | 'rateLimit' | 'server' | 'parse'
class HfException implements Exception {
  final String kind;
  final int? status;
  const HfException(this.kind, [this.status]);
  @override
  String toString() => 'HfException($kind${status != null ? ', $status' : ''})';
}

class HfService {
  HfService._();

  static const _timeout = Duration(seconds: 20);

  static String get base {
    final v = hfEndpointNotifier.value.trim();
    final raw = v.isEmpty ? kDefaultHfEndpoint : v;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static Map<String, String> headers() {
    final token = hfTokenNotifier.value.trim();
    return {
      'User-Agent': 'PicoChat',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Direct download URL ("resolve" redirects to the CDN).
  static String downloadUrl(String repo, String file) =>
      '$base/$repo/resolve/main/$file?download=true';

  static String pageUrl(String repo) => '$base/$repo';

  static Future<dynamic> _getJson(String url) async {
    try {
      final r = await http.get(Uri.parse(url), headers: headers()).timeout(_timeout);
      if (r.statusCode == 200) {
        try {
          return jsonDecode(utf8.decode(r.bodyBytes));
        } catch (_) {
          throw const HfException('parse');
        }
      }
      if (r.statusCode == 401 || r.statusCode == 403) throw HfException('auth', r.statusCode);
      if (r.statusCode == 404) throw HfException('notFound', r.statusCode);
      if (r.statusCode == 429) throw HfException('rateLimit', r.statusCode);
      throw HfException('server', r.statusCode);
    } on SocketException {
      throw const HfException('offline');
    } on TimeoutException {
      throw const HfException('offline');
    } on http.ClientException {
      throw const HfException('offline');
    }
  }

  /// Searches GGUF models, most downloaded first. Empty query = most popular.
  static Future<List<HfModelSummary>> search(String query, {int limit = 30}) async {
    final q = Uri(queryParameters: {
      if (query.trim().isNotEmpty) 'search': query.trim(),
      'filter': 'gguf',
      'sort': 'downloads',
      'direction': '-1',
      'limit': '$limit',
    }).query;
    final data = await _getJson('$base/api/models?$q');
    if (data is! List) throw const HfException('parse');
    return data
        .whereType<Map>()
        .map((e) => HfModelSummary.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.id.isNotEmpty)
        .toList();
  }

  /// Lists the single-file .gguf files of a repo, smallest first.
  /// Split files (-00001-of-00003) and vision projectors are skipped.
  static Future<List<HfFileInfo>> listGgufFiles(String repo) async {
    final data = await _getJson('$base/api/models/$repo/tree/main');
    if (data is! List) throw const HfException('parse');
    final split = RegExp(r'-\d{5}-of-\d{5}\.gguf$', caseSensitive: false);
    final files = <HfFileInfo>[];
    for (final e in data.whereType<Map>()) {
      final path = e['path'];
      if (e['type'] != 'file' || path is! String) continue;
      final lower = path.toLowerCase();
      if (!lower.endsWith('.gguf') || split.hasMatch(lower) || lower.contains('mmproj')) continue;
      final lfs = e['lfs'];
      final size = (lfs is Map ? lfs['size'] : null) ?? e['size'];
      files.add(HfFileInfo(path: path, size: (size as num?)?.toInt() ?? 0));
    }
    files.sort((a, b) => a.size.compareTo(b.size));
    return files;
  }

  /// Best default file: Q4_K_M first, then close relatives, else the smallest.
  static HfFileInfo? pickDefault(List<HfFileInfo> files) {
    files = files.where((f) => !f.path.toLowerCase().contains('mmproj')).toList();
    if (files.isEmpty) return null;
    for (final q in const ['Q4_K_M', 'Q4_K_S', 'Q4_0', 'Q5_K_M', 'Q4_K_L', 'Q8_0']) {
      for (final f in files) {
        if (f.quant == q) return f;
      }
    }
    return files.first;
  }
}
