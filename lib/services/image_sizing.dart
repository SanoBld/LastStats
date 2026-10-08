// lib/services/image_sizing.dart
//
// Rewrites an artwork URL to the resolution actually needed on screen.
// Each source has its own size syntax AND its own set of sizes it really
// serves; unknown hosts are returned unchanged.
//
// IMPORTANT: asking a CDN for a size it does not serve does not "round" to
// the nearest one — it answers with an error (Wikimedia: HTTP 429 for any
// non-standard thumbnail width), and the picture is then missing everywhere.
// So every host below only gets sizes from its own list. Display widgets
// additionally fall back to the ORIGINAL (un-resized) url when the resized
// one fails to load (_SmartImage, OfflineImageCache.image, TrackRowTile).

// Generic steps (iTunes / Apple, YouTube Music / Google accept any square).
const _buckets = [64, 128, 256, 400, 600, 1000, 1500, 3000];

// Deezer CDN: documented sizes of the API (56 / 250 / 500 / 1000 + 120).
const _deezerSteps = [120, 250, 500, 1000];

// Wikimedia only serves its standard thumbnail widths.
const _wikiSteps = [120, 250, 330, 500, 960, 1280, 1920];

int _pick(List<int> steps, double target) =>
    steps.firstWhere((b) => b >= target, orElse: () => steps.last);

String sizedImageUrl(String url, double logicalPx, double dpr) {
  if (url.isEmpty || !logicalPx.isFinite || logicalPx <= 0) return url;
  final target = logicalPx * (dpr <= 0 ? 2.0 : dpr);

  // iTunes / Apple: .../100x100bb.jpg (up to 3000)
  if (url.contains('mzstatic.com')) {
    final px = _pick(_buckets, target);
    return url.replaceFirst(RegExp(r'/\d+x\d+bb'), '/${px}x${px}bb');
  }
  // Deezer CDN: .../1000x1000-000000-80-0-0.jpg
  if (url.contains('dzcdn.net')) {
    final n = _pick(_deezerSteps, target);
    return url.replaceFirst(RegExp(r'/\d+x\d+-'), '/${n}x$n-');
  }
  // YouTube Music / Google: =w544-h544-l90-rj (keeps aspect ratio)
  final yt = RegExp(r'=w(\d+)-h(\d+)').firstMatch(url);
  if (yt != null && (url.contains('googleusercontent.com') || url.contains('ytimg.com'))) {
    final px = _pick(_buckets, target);
    final w = int.parse(yt.group(1)!), h = int.parse(yt.group(2)!);
    final k = px / (w > h ? w : h);
    final nw = (w * k).round(), nh = (h * k).round();
    return url.replaceFirst(RegExp(r'=w\d+-h\d+'), '=w$nw-h$nh');
  }
  // Wikipedia thumbnails: .../thumb/.../600px-Name.jpg (standard widths only)
  if (url.contains('upload.wikimedia.org') && url.contains('/thumb/')) {
    final n = _pick(_wikiSteps, target);
    return url.replaceFirst(RegExp(r'/\d+px-'), '/${n}px-');
  }
  // Cover Art Archive: front-250 / front-500 / front-1200
  final caa = RegExp(r'/front-(\d+)$').firstMatch(url);
  if (url.contains('coverartarchive.org') && caa != null) {
    final px = _pick(_buckets, target);
    final n = px <= 250 ? 250 : (px <= 500 ? 500 : 1200);
    return url.replaceFirst(RegExp(r'/front-\d+$'), '/front-$n');
  }
  return url;
}
