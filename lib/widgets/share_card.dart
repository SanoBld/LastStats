// Shared look for every exported share image (charts, news, recaps, badges...).
// Uses the real app logo and the app's Material colour scheme.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/m3_shapes.dart';

/// The real LastStats logo (assets/icons/app_logo.svg), tinted with [color].
class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;
  const AppLogo({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      'assets/icons/app_logo.svg',
      width: size, height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
  }
}

/// Soft decorative Material shape (cookie / burst) for card corners.
class ShareBlob extends StatelessWidget {
  final double size;
  final Color color;
  final int lobes;
  final double amplitude;
  const ShareBlob({
    super.key,
    required this.size,
    required this.color,
    this.lobes = 8,
    this.amplitude = 0.07,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: ShapeDecoration(
          color: color,
          shape: M3CookieBorder(lobes: lobes, amplitude: amplitude),
        ),
      );
}

/// Small corner mark: "LastStats" + logo. Put it bottom right.
class ShareMark extends StatelessWidget {
  final Color color;
  final double k;
  const ShareMark({super.key, required this.color, this.k = 1});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('LastStats', style: TextStyle(
              color: color, fontSize: 11 * k, fontWeight: FontWeight.w700)),
          SizedBox(width: 8 * k),
          AppLogo(size: 26 * k, color: color),
        ],
      );
}

/// Rank number inside a cookie shape.
class ShareRank extends StatelessWidget {
  final int n;
  final double size;
  const ShareRank({super.key, required this.n, this.size = 26});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      width: size, height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: n == 1 ? s.primary : s.primaryContainer,
        shape: const M3CookieBorder(lobes: 8, amplitude: 0.07),
      ),
      child: Text('$n', style: TextStyle(
          fontSize: size * 0.5, fontWeight: FontWeight.w900,
          color: n == 1 ? s.onPrimary : s.onPrimaryContainer)),
    );
  }
}

/// Section label (e.g. "ARTISTS") with a small shape in front.
class ShareLabel extends StatelessWidget {
  final String text;
  final double k;
  const ShareLabel(this.text, {super.key, this.k = 1});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      ShareBlob(size: 12 * k, color: s.primary, lobes: 6, amplitude: 0.18),
      SizedBox(width: 8 * k),
      Text(text.toUpperCase(), style: TextStyle(
          color: s.primary, fontSize: 11 * k,
          fontWeight: FontWeight.w800, letterSpacing: 0.8)),
    ]);
  }
}

/// Stat tile: big value + small label, same radius everywhere.
class ShareTile extends StatelessWidget {
  final String label, value;
  final double k;
  const ShareTile({super.key, required this.label, required this.value, this.k = 1});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 10 * k, horizontal: 6 * k),
      decoration: BoxDecoration(
        color: s.primaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18 * k),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: s.onPrimaryContainer,
                fontSize: 18 * k, fontWeight: FontWeight.w900)),
        SizedBox(height: 2 * k),
        Text(label, maxLines: 2, textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: s.onPrimaryContainer.withValues(alpha: 0.8),
                fontSize: 10 * k, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Frame around the content of a share image.
/// [width] is the full image width; everything else scales with it
/// (base design = 1080), so text stays readable at any size.
class ShareCardFrame extends StatelessWidget {
  final double width;
  final String title;
  final String? badge;      // e.g. the year
  final Color? accent;      // badge colour (defaults to primary)
  final Widget child;
  final String footer;
  const ShareCardFrame({
    super.key,
    required this.width,
    required this.title,
    required this.child,
    required this.footer,
    this.badge,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final k = width / 1080;
    final tone = accent ?? s.primary;

    return Container(
      width: width,
      padding: EdgeInsets.all(28 * k),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [s.primaryContainer.withValues(alpha: 0.55), s.surface],
        ),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: s.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(40 * k),
        ),
        child: Stack(children: [
          Positioned(
            top: -70 * k, right: -70 * k,
            child: ShareBlob(
                size: 240 * k, color: s.primary.withValues(alpha: 0.10)),
          ),
          Positioned(
            bottom: -90 * k, left: -60 * k,
            child: ShareBlob(
                size: 220 * k, lobes: 12,
                color: s.tertiary.withValues(alpha: 0.10)),
          ),
          Padding(
            padding: EdgeInsets.all(36 * k),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(
                    width: 92 * k, height: 92 * k,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: s.primary,
                      shape: const M3CookieBorder(lobes: 8, amplitude: 0.07),
                    ),
                    child: AppLogo(size: 60 * k, color: s.onPrimary),
                  ),
                  SizedBox(width: 20 * k),
                  Text('LastStats', style: TextStyle(
                      fontSize: 36 * k, fontWeight: FontWeight.w800,
                      letterSpacing: -0.2, color: s.onSurface)),
                  const Spacer(),
                  if (badge != null && badge!.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 22 * k, vertical: 11 * k),
                      decoration: BoxDecoration(
                        color: accent == null ? s.primaryContainer : tone,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(badge!, style: TextStyle(
                          fontSize: 20 * k, fontWeight: FontWeight.w800,
                          color: accent == null
                              ? s.onPrimaryContainer
                              : ThemeData.estimateBrightnessForColor(tone) ==
                                      Brightness.dark
                                  ? Colors.white : Colors.black)),
                    ),
                ]),
                SizedBox(height: 30 * k),
                Text(title, style: TextStyle(
                    fontSize: 44 * k, fontWeight: FontWeight.w800,
                    height: 1.1, letterSpacing: -0.5, color: s.onSurface)),
                SizedBox(height: 26 * k),
                child,
                if (footer.isNotEmpty) ...[
                  SizedBox(height: 24 * k),
                  Text(footer, style: TextStyle(
                      fontSize: 18 * k, fontWeight: FontWeight.w600,
                      color: s.onSurfaceVariant)),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
