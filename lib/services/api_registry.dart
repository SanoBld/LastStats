// lib/services/api_registry.dart
// ══════════════════════════════════════════════════════════════════════════
//  Every external service the app talks to, with its published (or, when
//  nothing is published, observed) rate limit and the lower ceiling the app
//  imposes on itself so it stays clear of it.
//
//  Sources (checked October 2026):
//    Last.fm      last.fm/api/tos + error codes: no number is published,
//                 "your IP made too many requests" (29). ~5 req/s per IP is
//                 the commonly documented guidance. ToS also caps the stored
//                 Last.fm data at 100 MB and forbids circumventing limits.
//    MusicBrainz  musicbrainz.org/doc/MusicBrainz_API/Rate_Limiting: 1 req/s
//                 per IP, descriptive User-Agent required, 503 when exceeded.
//    Deezer       50 requests / 5 s per IP (error code 4 "Quota limit").
//    iTunes       ~20 calls / minute (Apple docs, "subject to change").
//    TheAudioDB   free test key "123": 30 requests / minute.
//    ListenBrainz limits are sent in X-RateLimit-* response headers.
//    GitHub API   60 requests / hour / IP without a token (X-RateLimit-*).
//    Others       no limit published → tracked only; unofficial endpoints
//                 are flagged because they can change or block at any time.
// ══════════════════════════════════════════════════════════════════════════

enum ApiCategory { listening, artwork, metadata, lyrics, translate, updates, other }

/// [requests] allowed per [windowMs].
class ApiRule {
  final int requests;
  final int windowMs;
  const ApiRule(this.requests, this.windowMs);

  int get windowSeconds => (windowMs / 1000).round();
}

class ApiDef {
  final String id;
  final String name;
  final ApiCategory category;
  final List<String> hosts;

  /// Limit published by the provider (null = nothing published).
  final ApiRule? official;

  /// Ceiling enforced by the app itself (null = not throttled, tracked only).
  final ApiRule? ceiling;

  /// How long a request may queue for a free slot before it is skipped.
  /// 0 = wait (bounded to 60 s).
  final int maxWaitMs;

  /// Pause applied after a rate-limit answer when the server gives no
  /// Retry-After.
  final int cooldownMs;

  /// Not an official/public API (may change or block without notice).
  final bool unofficial;

  /// Uses a shared public test key rather than a personal one.
  final bool sharedKey;

  /// Limit/remaining are announced in X-RateLimit-* response headers.
  final bool headerLimits;

  /// Provider asks for an identifying User-Agent.
  final bool needsUserAgent;

  const ApiDef({
    required this.id,
    required this.name,
    required this.category,
    this.hosts = const [],
    this.official,
    this.ceiling,
    this.maxWaitMs = 0,
    this.cooldownMs = 30000,
    this.unofficial = false,
    this.sharedKey = false,
    this.headerLimits = false,
    this.needsUserAgent = false,
  });
}

class ApiRegistry {
  ApiRegistry._();

  /// Last.fm data may not exceed this much storage (API Terms, clause 4.3.4).
  static const lastfmStorageCapBytes = 100 * 1024 * 1024;

  static const _lastfm = ApiDef(
    id: 'lastfm', name: 'Last.fm', category: ApiCategory.listening,
    hosts: ['ws.audioscrobbler.com'],
    official: ApiRule(5, 1000),   // guidance: ~5 req/s per IP (not enforced in writing)
    ceiling:  ApiRule(4, 1000),
    maxWaitMs: 10000, cooldownMs: 30000,
  );

  static const all = <ApiDef>[
    _lastfm,
    ApiDef(
      id: 'listenbrainz', name: 'ListenBrainz', category: ApiCategory.listening,
      hosts: ['api.listenbrainz.org'],
      headerLimits: true, maxWaitMs: 8000,
    ),
    ApiDef(
      id: 'musicbrainz', name: 'MusicBrainz', category: ApiCategory.metadata,
      hosts: ['musicbrainz.org'],
      official: ApiRule(1, 1000),
      ceiling:  ApiRule(1, 1100),
      maxWaitMs: 4000, cooldownMs: 30000, needsUserAgent: true,
    ),
    ApiDef(
      id: 'coverart', name: 'Cover Art Archive', category: ApiCategory.artwork,
      hosts: ['coverartarchive.org'],
      needsUserAgent: true,
    ),
    ApiDef(
      id: 'itunes', name: 'iTunes Search', category: ApiCategory.artwork,
      hosts: ['itunes.apple.com'],
      official: ApiRule(20, 60000),
      ceiling:  ApiRule(18, 60000),
      maxWaitMs: 2500, cooldownMs: 60000,
    ),
    ApiDef(
      id: 'deezer', name: 'Deezer', category: ApiCategory.artwork,
      hosts: ['api.deezer.com'],
      official: ApiRule(50, 5000),
      ceiling:  ApiRule(40, 5000),
      maxWaitMs: 3000, cooldownMs: 10000,
    ),
    ApiDef(
      id: 'audiodb', name: 'TheAudioDB', category: ApiCategory.artwork,
      hosts: ['www.theaudiodb.com'],
      official: ApiRule(30, 60000),
      ceiling:  ApiRule(28, 60000),
      maxWaitMs: 2500, cooldownMs: 60000, sharedKey: true,
    ),
    ApiDef(
      id: 'wikimedia', name: 'Wikipedia / Wikimedia Commons', category: ApiCategory.artwork,
      hosts: ['en.wikipedia.org', 'commons.wikimedia.org'],
      ceiling: ApiRule(8, 1000),
      maxWaitMs: 3000, needsUserAgent: true,
    ),
    ApiDef(
      id: 'ytmusic', name: 'YouTube Music', category: ApiCategory.artwork,
      hosts: ['music.youtube.com'],
      ceiling: ApiRule(10, 10000),
      maxWaitMs: 3000, unofficial: true,
    ),
    ApiDef(
      id: 'applemusic', name: 'Apple Music (animated covers)', category: ApiCategory.artwork,
      hosts: ['amp-api.music.apple.com', 'music.apple.com'],
      ceiling: ApiRule(10, 10000),
      maxWaitMs: 3000, unofficial: true,
    ),
    ApiDef(
      id: 'lrclib', name: 'LRCLIB', category: ApiCategory.lyrics,
      hosts: ['lrclib.net'],
      needsUserAgent: true,
    ),
    ApiDef(
      id: 'translate', name: 'Google Translate', category: ApiCategory.translate,
      hosts: ['translate.googleapis.com'],
      ceiling: ApiRule(10, 10000),
      maxWaitMs: 5000, unofficial: true,
    ),
    ApiDef(
      id: 'github', name: 'GitHub API', category: ApiCategory.updates,
      hosts: ['api.github.com'],
      official: ApiRule(60, 3600000),
      headerLimits: true, maxWaitMs: 1000, needsUserAgent: true,
    ),
    ApiDef(
      id: 'githubstatic', name: 'GitHub Pages / raw', category: ApiCategory.updates,
      hosts: ['raw.githubusercontent.com', 'sanobld.github.io'],
    ),
  ];

  /// Image / media downloads from CDNs (Last.fm, Apple, Deezer…): tracked
  /// together, never throttled.
  static const cdn = ApiDef(
    id: 'cdn', name: 'Image CDNs', category: ApiCategory.other,
  );

  static final Map<String, ApiDef> _byId = {
    for (final d in all) d.id: d,
    cdn.id: cdn,
  };

  static final Map<String, ApiDef> _byHost = {
    for (final d in all) for (final h in d.hosts) h: d,
  };

  static ApiDef? byId(String id) => _byId[id];

  /// Definition for [host]; anything unknown is a CDN/other download.
  static ApiDef forHost(String host) => _byHost[host.toLowerCase()] ?? cdn;
}
