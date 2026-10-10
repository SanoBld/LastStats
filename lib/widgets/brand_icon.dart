// Brand logo from assets/icons (lastfm.svg, spotify.svg). If the file is
// missing, a Material icon is shown instead.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

class BrandIcon extends StatelessWidget {
  final String asset;
  final IconData fallback;
  final double size;
  final Color? color;
  const BrandIcon(this.asset, this.fallback, {super.key, this.size = 24, this.color});

  static final Map<String, bool> _has = {};

  Future<bool> _exists() async {
    final k = _has[asset];
    if (k != null) return k;
    try {
      await rootBundle.load(asset);
      return _has[asset] = true;
    } catch (_) {
      return _has[asset] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final fb = Icon(fallback, size: size, color: c);
    return FutureBuilder<bool>(
      future: _exists(),
      builder: (_, snap) => snap.data != true
          ? fb
          : SvgPicture.asset(asset,
              width: size, height: size,
              colorFilter: ColorFilter.mode(c, BlendMode.srcIn)),
    );
  }
}
