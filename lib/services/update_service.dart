import 'dart:convert';
import 'dart:ffi' show Abi;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

enum UpdateChannel { stable, beta }

enum DownloadKind { apk, installer, zip, none }

class UpdateService {
  UpdateService._();

  static const _owner = 'SanoBld';
  static const _repo  = 'LastStats';

  static String currentVersion = '0.0.0';
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) currentVersion = info.version;
    } catch (_) {}
  }

  static const _timeout = Duration(seconds: 10);

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

      final candidates = list
          .cast<Map<String, dynamic>>()
          .where((r) => r['draft'] != true)
          .where((r) => channel == UpdateChannel.beta || r['prerelease'] != true)
          .toList();

      if (candidates.isEmpty) return null;

      final release = candidates.first;

      final rawTag = (release['tag_name'] ?? '').toString();
      final latest = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;
      if (latest.isEmpty) return null;
      if (!_isNewer(latest, currentVersion)) return null;

      final assets = (release['assets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final match = _bestAssetForPlatform(assets);

      return UpdateInfo(
        version:     latest,
        releaseUrl:  (release['html_url'] ?? '').toString(),
        downloadUrl: match.$1,
        downloadKind: match.$2,
        notes:       (release['body'] ?? '').toString(),
        publishedAt: _parseDate(release['published_at']?.toString()),
        isBeta:      release['prerelease'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  // Picks the right release asset for the current OS + CPU architecture.
  // Abi.current() is built into dart:ffi — no extra package needed.
  static (String?, DownloadKind) _bestAssetForPlatform(List<Map<String, dynamic>> assets) {
    String? find(String name) {
      for (final a in assets) {
        if ((a['name'] ?? '') == name) return (a['browser_download_url'] ?? '').toString();
      }
      return null;
    }

    final universal = find('app-universal-release.apk');

    switch (Abi.current()) {
      case Abi.androidArm64:
        return (find('app-arm64-v8a-release.apk') ?? universal, DownloadKind.apk);
      case Abi.androidArm:
        return (find('app-armeabi-v7a-release.apk') ?? universal, DownloadKind.apk);
      case Abi.androidX64:
        return (find('app-x86_64-release.apk') ?? universal, DownloadKind.apk);
      case Abi.androidIA32:
        return (universal, DownloadKind.apk);

      case Abi.windowsArm64:
        final exe = find('LastStats-Setup-arm64.exe');
        if (exe != null) return (exe, DownloadKind.installer);
        return (find('laststats-windows-arm64.zip'), DownloadKind.zip);
      case Abi.windowsX64:
      case Abi.windowsIA32:
        final exe = find('LastStats-Setup-x64.exe');
        if (exe != null) return (exe, DownloadKind.installer);
        return (find('laststats-windows.zip'), DownloadKind.zip);

      case Abi.macosArm64:
      case Abi.macosX64:
        return (find('laststats-macos.zip'), DownloadKind.zip);

      case Abi.linuxArm64:
      case Abi.linuxX64:
      case Abi.linuxIA32:
        return (find('laststats-linux.zip'), DownloadKind.zip);

      default:
        return (universal, universal != null ? DownloadKind.apk : DownloadKind.none);
    }
  }

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
    final core = v.split('-').first;
    return core.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  }

  static DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try { return DateTime.parse(s); } catch (_) { return null; }
  }
}

class UpdateInfo {
  final String       version;
  final String       releaseUrl;
  final String?      downloadUrl;
  final DownloadKind downloadKind;
  final String       notes;
  final DateTime?    publishedAt;
  final bool         isBeta;

  const UpdateInfo({
    required this.version,
    required this.releaseUrl,
    this.downloadUrl,
    this.downloadKind = DownloadKind.none,
    required this.notes,
    this.publishedAt,
    this.isBeta = false,
  });

  bool get hasDownload => downloadUrl != null && downloadUrl!.isNotEmpty;
}