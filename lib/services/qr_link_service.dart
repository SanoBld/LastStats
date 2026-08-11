// lib/services/qr_link_service.dart
// Builds and parses the two QR payload formats a profile card can encode:
//   - laststats://profile/<username>   (opens straight into this app)
//   - https://www.last.fm/user/<username>  (opens the Last.fm website)
// No network calls — just string building/parsing.

class QrLinkService {
  QrLinkService._();

  static String appLink(String username) => 'laststats://profile/$username';
  static String webLink(String username) => 'https://www.last.fm/user/$username';

  /// Returns the username encoded in [raw] if it matches either format,
  /// or null if the scanned text isn't a recognized profile link.
  static String? usernameFromScan(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    // laststats://profile/<username>
    final appMatch = RegExp(r'^laststats://profile/([^/?#]+)').firstMatch(text);
    if (appMatch != null) return Uri.decodeComponent(appMatch.group(1)!);

    // https://www.last.fm/user/<username> (with or without www, http/https)
    final webMatch = RegExp(r'^https?://(?:www\.)?last\.fm/user/([^/?#]+)').firstMatch(text);
    if (webMatch != null) return Uri.decodeComponent(webMatch.group(1)!);

    return null;
  }
}
