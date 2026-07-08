import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

// ══════════════════════════════════════════════════════════════════════════
//  UpdateService — reads update info directly from the GitHub Releases API.
//  No static JSON file needed (the old gh-pages metadata approach was
//  unreliable since publish-update-metadata.yml could silently fail or the
//  file could be stale). The Releases API is always authoritative and free,
//  no auth required for public repos (60 req/h per IP, plenty for this use).
// ══════════════════════════════════════════════════════════════════════════

enum UpdateChannel { stable, beta }

class UpdateService {
  UpdateService._();

  // ─── Your real GitHub repo (owner/name) ───────────────────────────────
  static const _owner = 'SanoBld';
  static const _repo  = 'LastStats';

  // Read at runtime from pubspec.yaml's `version:` field (via package_info)
  // instead of a value hardcoded here. No more manual/CI sed injection to
  // keep in sync — this is always correct, in dev builds and CI builds alike.
  // Falls back to '0.0.0' only if init() hasn't been called yet.
  static String currentVersion = '0.0.0';

  static bool _initialized = false;

  /// Call once at app startup (main.dart), before anything reads
  /// [currentVersion] or calls [checkForUpdate].
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final info = await PackageInfo.fromPlatform();
      // info.version is the pubspec `version:` field before the '+buildNumber'.
      if (info.version.isNotEmpty) currentVersion = info.version;
    } catch (_) {
      // Keep the '0.0.0' fallback — checkForUpdate() will then just always
      // report an update is available rather than crashing, which is the
      // safer failure mode.
    }
  }
  // ────────────────────────────────────────────────────────────────────────

  static const _timeout = Duration(seconds: 10);

  /// Returns an [UpdateInfo] if a newer version exists, or `null` if up to
  /// date / on network error.
  ///
  /// [channel] picks which releases to consider:
  ///   stable → only non-prerelease releases (tags without a '-' suffix)
  ///   beta   → the single most recent release of any kind (so beta users
  ///            see pre-releases AND get notified when stable catches up)
  static Future<UpdateInfo?> checkForUpdate({
    UpdateChannel channel = UpdateChannel.stable,
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/$_owner/$_repo/releases?per_page=10',
      );
      final res = await http.get(uri, headers: const {
        'Accept': 'application/vnd.github+json',
      }).timeout(_timeout);

      if (res.statusCode != 200) return null;

      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      if (list.isEmpty) return null;

      // Drop drafts always; for the stable channel also drop pre-releases.
      final candidates = list
          .cast<Map<String, dynamic>>()
          .where((r) => r['draft'] != true)
          .where((r) => channel == UpdateChannel.beta || r['prerelease'] != true)
          .toList();

      if (candidates.isEmpty) return null;

      // GitHub returns releases already sorted by creation date, newest first.
      final release = candidates.first;

      final rawTag = (release['tag_name'] ?? '').toString();
      final latest = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;
      if (latest.isEmpty) return null;
      if (!_isNewer(latest, currentVersion)) return null;

      final assets = (release['assets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      String? findAsset(String name) {
        for (final a in assets) {
          if ((a['name'] ?? '') == name) return (a['browser_download_url'] ?? '').toString();
        }
        return null;
      }

      // Universal APK preferred for the single-button download action.
      final apkUrl = findAsset('app-universal-release.apk');

      return UpdateInfo(
        version:     latest,
        releaseUrl:  (release['html_url'] ?? '').toString(),
        apkUrl:      apkUrl,
        notes:       (release['body'] ?? '').toString(),
        publishedAt: _parseDate(release['published_at']?.toString()),
        isBeta:      release['prerelease'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Compare semver, ignoring any "-beta"/"-rc1" suffix ─────────────────
  // Pre-release suffixes only affect the isBeta flag (set from the API's
  // own "prerelease" boolean) — version *ordering* still compares numerically
  // so a "2.7.0-beta" tag is correctly treated as newer than "2.6.0".
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

  static List<int> _parts(String v) {
    // Strip "-beta", "-rc1" etc. before splitting on dots.
    final core = v.split('-').first;
    return core.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  }

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