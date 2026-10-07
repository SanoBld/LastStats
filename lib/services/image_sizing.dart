// lib/services/image_sizing.dart
//
// Rewrites an artwork URL to the resolution actually needed on screen.
// Each source has its own size syntax; unknown hosts are returned unchanged.
// Sizes snap to a few buckets so the disk cache is reused across screens.

const _buckets = [64, 128, 256, 400, 600, 1000, 1500, 3000];

String sizedImageUrl(String url, double logicalPx, double dpr) {
  if (url.isEmpty || !logicalPx.isFinite || logicalPx <= 0) return url;
  final target = logicalPx * (dpr <= 0 ? 2.0 : dpr);
  final px = _buckets.firstWhere((b) => b >= target, orElse: () => 3000);

  // iTunes / Apple: .../100x100bb.jpg (up to 3000)
  if (url.contains('mzstatic.com')) {
    return url.replaceFirst(RegExp(r'/\d+x\d+bb'), '/${px}x${px}bb');
  }
  // Deezer CDN: .../1000x1000-000000-80-0-0.jpg (1000 is plenty)
  if (url.contains('dzcdn.net')) {
    final n = px > 1000 ? 1000 : px;
    return url.replaceFirst(RegExp(r'/\d+x\d+-'), '/${n}x$n-');
  }
  // YouTube Music / Google: =w544-h544-l90-rj (keeps aspect ratio)
  final yt = RegExp(r'=w(\d+)-h(\d+)').firstMatch(url);
  if (yt != null && (url.contains('googleusercontent.com') || url.contains('ytimg.com'))) {
    final w = int.parse(yt.group(1)!), h = int.parse(yt.group(2)!);
    final k = px / (w > h ? w : h);
    final nw = (w * k).round(), nh = (h * k).round();
    return url.replaceFirst(RegExp(r'=w\d+-h\d+'), '=w$nw-h$nh');
  }
  // Wikipedia thumbnails: .../thumb/.../600px-Name.jpg
  if (url.contains('upload.wikimedia.org') && url.contains('/thumb/')) {
    final n = px > 1500 ? 1500 : px;
    return url.replaceFirst(RegExp(r'/\d+px-'), '/${n}px-');
  }
  // Cover Art Archive: front-250 / front-500 / front-1200
  final caa = RegExp(r'/front-(\d+)$').firstMatch(url);
  if (url.contains('coverartarchive.org') && caa != null) {
    final n = px <= 250 ? 250 : (px <= 500 ? 500 : 1200);
    return url.replaceFirst(RegExp(r'/front-\d+$'), '/front-$n');
  }
  return url;
}
