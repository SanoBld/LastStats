// lib/services/web_img_stub.dart
// Native fallback — returns null so OfflineImageCache.image() falls back
// to the normal Image/NetworkImage pipeline (no CORS issue on native).
import 'package:flutter/widgets.dart';

Widget? buildCorsBypassImage(
  String url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) => null;
