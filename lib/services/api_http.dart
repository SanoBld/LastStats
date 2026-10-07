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
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'api_registry.dart';
import 'api_usage.dart';

class ApiHttp {
  ApiHttp._();

  static const userAgent = 'LastStats (+https://github.com/SanoBld/LastStats)';

  static final _lastfmRate = RegExp(r'"error"\s*:\s*"?29"?\b');
  static final _deezerQuota = RegExp(r'"code"\s*:\s*4\b');

  /// [api] forces an API id (e.g. 'cdn' for image downloads); otherwise it is
  /// derived from the host. [keyLabel] tags Last.fm calls by key in use.
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    String? api,
    String? keyLabel,
  }) =>
      _run(url, api, keyLabel, headers, (h) => http.get(url, headers: h));

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    String? api,
    String? keyLabel,
  }) =>
      _run(url, api, keyLabel, headers,
          (h) => http.post(url, headers: h, body: body, encoding: encoding));

  static Future<http.Response> _run(
    Uri url,
    String? api,
    String? keyLabel,
    Map<String, String>? headers,
    Future<http.Response> Function(Map<String, String>? headers) send,
  ) async {
    final def =
        (api != null ? ApiRegistry.byId(api) : null) ?? ApiRegistry.forHost(url.host);

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
      res = await send(h);
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
      final ra = int.tryParse(res.headers['retry-after'] ?? '');
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
