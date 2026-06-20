// lib/services/web_img_web.dart
//
// CanvasKit/skwasm renderers need CORS headers to decode network image
// bytes into a texture. A plain HTML <img> element doesn't have that
// restriction — browsers always allow *displaying* cross-origin images,
// they only block reading their pixel data back into JS/canvas (which
// Flutter doesn't need here, it just paints the element).
//
// This is Flutter's own documented workaround for non-CORS image hosts:
// https://docs.flutter.dev/platform-integration/web/web-images
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredViews = {};

Widget? buildCorsBypassImage(
  String url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (url.isEmpty) return null;
  final viewType = 'ls-img-${url.hashCode}-${fit.index}';

  // registerViewFactory must only be called once per viewType.
  if (!_registeredViews.contains(viewType)) {
    _registeredViews.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      return web.HTMLImageElement()
        ..src = url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = _cssFit(fit)
        ..style.display = 'block';
    });
  }

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewType, key: ValueKey(url)),
  );
}

String _cssFit(BoxFit fit) {
  switch (fit) {
    case BoxFit.contain:   return 'contain';
    case BoxFit.fill:      return 'fill';
    case BoxFit.none:      return 'none';
    case BoxFit.scaleDown: return 'scale-down';
    default:               return 'cover';
  }
}
