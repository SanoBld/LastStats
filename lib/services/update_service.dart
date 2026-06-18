import 'dart:convert';
import 'package:http/http.dart' as http;

// ══════════════════════════════════════════════════════════════════════════
//  UpdateService — reads update info from a static JSON file hosted on
//  GitHub Pages (gh-pages branch). No GitHub API call, no auth, no rate limit.
// ══════════════════════════════════════════════════════════════════════════

enum UpdateChannel { stable, beta }

class UpdateService {
  UpdateService._();

  // ─── Set to your own GitHub Pages base URL ────────────────────────────
  static const _pagesBase     = 'https://sanobld.github.io/LastStats';
  static const currentVersion = '2.6.0';
  // ────────────────────────────────────────────────────────────────────────

  static const _timeout = Duration(seconds: 10);

  /// Returns an [UpdateInfo] if a newer version exists, or `null` if up to
  /// date / on network error. [channel] picks stable or beta metadata file.
  static Future<UpdateInfo?> checkForUpdate({
    UpdateChannel channel = UpdateChannel.stable,
  }) async {
    final filename = channel == UpdateChannel.beta ? 'update_beta.json' : 'update.json';
    try {
      final uri = Uri.parse('$_pagesBase/$filename');
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return null;

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final rawTag = (data['version'] ?? data['tag'] ?? '').toString();
      final latest = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;

      if (latest.isEmpty) return null;
      if (!_isNewer(latest, currentVersion)) return null;

      return UpdateInfo(
        version:     latest,
        releaseUrl:  (data['release_url'] ?? '').toString(),
        apkUrl:      (data['apk_url'] ?? '').toString(),
        notes:       (data['notes'] ?? '').toString(),
        publishedAt: _parseDate(data['published_at']?.toString()),
        isBeta:      channel == UpdateChannel.beta,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Compare semver X.Y.Z ───────────────────────────────────────────────
  static bool _isNewer(String latest, String current) {
    final l = _parts(latest);
    final c = _parts(current);
    for (var i = 0; i < 3; i++) {
      final lv = i < l.length ? l[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
  }

  static List<int> _parts(String v) =>
      v.split('.').map((s) => int.tryParse(s) ?? 0).toList();

  static DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try { return DateTime.parse(s); } catch (_) { return null; }
  }
}

// ══════════════════════════════════════════════════════════════════════════

class UpdateInfo {
  final String    version;
  final String    releaseUrl;
  final String?   apkUrl;
  final String    notes;
  final DateTime? publishedAt;
  final bool      isBeta;

  const UpdateInfo({
    required this.version,
    required this.releaseUrl,
    this.apkUrl,
    required this.notes,
    this.publishedAt,
    this.isBeta = false,
  });

  bool get hasApk => apkUrl != null && apkUrl!.isNotEmpty;
}