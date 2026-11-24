// lib/services/api_http.dart
// ══════════════════════════════════════════════════════════════════════════
//  Drop-in replacement for http.get / http.post that
//    1. figures out which API the request goes to (from its host),
//    2. waits for a free slot (or skips) so provider limits are respected,
//    3. counts the call, its outcome and any rate-limit answer
//       (see ApiUsage), and pauses the API after one.
//
//  Same signature and same Future<http.Response> as package:http, so the
//  callers' own .timeout(...) / try-catch keep working unchanged.
//  A request skipped by the limiter returns a synthetic 429 response (header
//  x-laststats-skipped: 1) — every caller already treats non-200 as "no data"
//  and moves on to its next source.
// ══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:http/http.dart' as http;
import 'api_registry.dart';
import 'data_source.dart';
import 'api_usage.dart';

class ApiHttp {
  ApiHttp._();

  // Format required by MetaBrainz: "Application name/<version> ( contact-url )"
  static const userAgent = 'LastStats/4.3 ( https://github.com/SanoBld/LastStats )';

  // ONE shared client: connections are kept alive and reused. A new client
  // per call opened a fresh TLS handshake each time, and the ListenBrainz
  // firewall drops bursts of new connections ("terminated during handshake").
  static final http.Client _client = http.Client();

  static final _lastfmRate = RegExp(r'"error"\s*:\s*"?29"?\b');
  static final _deezerQuota = RegExp(r'"code"\s*:\s*4\b');

  /// [api] forces an API id (e.g. 'cdn' for image downloads); otherwise it is
  /// derived from the host. [keyLabel] tags Last.fm calls by key in use.
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    String? api,
    String? keyLabel,
    Duration? timeout,
  }) =>
      _run(url, api, keyLabel, headers, timeout, (h) => _client.get(url, headers: h));


  /// Decodes a JSON response body. When the server answers with an HTML page
  /// (maintenance, Cloudflare / proxy error, captive portal…) it throws a
  /// short readable [ApiBadResponse] instead of a raw FormatException that
  /// would dump "<!DOCTYPE html>…" on screen.
  static dynamic decodeJson(http.Response res) {
    final text = utf8.decode(res.bodyBytes, allowMalformed: true);
    final head = text.trimLeft();
    if (head.startsWith('<') || head.isEmpty) {
      throw ApiBadResponse(res.statusCode, res.request?.url.host ?? '');
    }
    try {
      return jsonDecode(text);
    } on FormatException {
      throw ApiBadResponse(res.statusCode, res.request?.url.host ?? '');
    }
  }

  /// Same result and same errors as [decodeJson], but big bodies (long
  /// scrobble pages, lists of stats…) are parsed in a background isolate so
  /// the interface never freezes while they are decoded.
  static Future<dynamic> decodeJsonAsync(http.Response res) async {
    // Small bodies: starting an isolate would cost more than parsing here.
    if (res.bodyBytes.length < 32 * 1024) return decodeJson(res);
    final out = await compute(_decodeJsonBytes, res.bodyBytes);
    if (out[0] != true) {
      throw ApiBadResponse(res.statusCode, res.request?.url.host ?? '');
    }
    return out[1];
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    String? api,
    String? keyLabel,
    Duration? timeout,
  }) =>
      _run(url, api, keyLabel, headers, timeout,
          (h) => _client.post(url, headers: h, body: body, encoding: encoding));

  static Future<http.Response> _run(
    Uri url,
    String? api,
    String? keyLabel,
    Map<String, String>? headers,
    Duration? timeout,
    Future<http.Response> Function(Map<String, String>? headers) send,
  ) async {
    final def =
        (api != null ? ApiRegistry.byId(api) : null) ?? ApiRegistry.forHost(url.host);

    // ListenBrainz mode: the Last.fm API is never contacted (and never counted).
    if (DataSource.lb && def.id == 'lastfm') {
      return http.Response('', 403,
          reasonPhrase: 'Last.fm is disabled in ListenBrainz mode',
          headers: const {'x-laststats-blocked': '1'});
    }

    Map<String, String>? h = headers;
    if (def.needsUserAgent && !kIsWeb) {
      final has = headers?.keys.any((k) => k.toLowerCase() == 'user-agent') ?? false;
      if (!has) h = {...?headers, 'User-Agent': userAgent};
    }

    if (!await ApiUsage.acquire(def)) {
      ApiUsage.recordSkipped(def.id);
      return http.Response('', 429,
          reasonPhrase: 'Skipped by client rate limiter',
          headers: const {'x-laststats-skipped': '1'});
    }

    http.Response res;
    try {
      // timeout covers only the network round trip, not the limiter wait
      res = timeout == null ? await send(h) : await send(h).timeout(timeout);
    } catch (e) {
      ApiUsage.recordCall(def.id, status: 0, error: true, keyLabel: keyLabel);
      rethrow;
    }

    var throttled = res.statusCode == 429 ||
        (res.statusCode == 503 && def.id == 'musicbrainz');

    // Some APIs answer 200 with a rate-limit error in the JSON body.
    if (!throttled &&
        res.bodyBytes.length < 1500 &&
        (def.id == 'lastfm' || def.id == 'deezer')) {
      final b = res.body;
      if (def.id == 'lastfm' && _lastfmRate.hasMatch(b)) throttled = true;
      if (def.id == 'deezer' && b.contains('"error"') && _deezerQuota.hasMatch(b)) {
        throttled = true;
      }
    }

    if (def.headerLimits) ApiUsage.noteHeaders(def.id, res.headers);

    if (throttled) {
      final ra = int.tryParse(res.headers['retry-after'] ??
          res.headers['x-ratelimit-reset-in'] ?? '');
      ApiUsage.reportThrottled(def.id, retryAfterMs: ra == null ? null : ra * 1000);
    }

    final code = res.statusCode;
    ApiUsage.recordCall(
      def.id,
      status: code,
      throttled: throttled,
      error: code >= 500 || code == 401 || code == 403,
      keyLabel: keyLabel,
    );
    return res;
  }
}

/// Thrown when an API answers with something that is not JSON (HTML error
/// page, empty body…). The message is short and safe to show to the user.
class ApiBadResponse implements Exception {
  final int status;
  final String host;
  const ApiBadResponse(this.status, this.host);
  @override
  String toString() =>
      'Invalid server response${host.isEmpty ? '' : ' ($host)'} – HTTP $status';
}

// Runs in a background isolate: [true, value] or [false, null] when the body
// is not JSON (HTML error page, empty, malformed) — same rules as decodeJson.
List<Object?> _decodeJsonBytes(List<int> bytes) {
  final text = utf8.decode(bytes, allowMalformed: true);
  final head = text.trimLeft();
  if (head.startsWith('<') || head.isEmpty) return [false, null];
  try {
    return [true, jsonDecode(text)];
  } on FormatException {
    return [false, null];
  }
}
