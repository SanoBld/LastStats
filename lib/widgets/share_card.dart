// Shared look for every exported share image (charts, news...).
// Uses the real app logo and the app's Material colour scheme.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
        padding: EdgeInsets.all(36 * k),
        decoration: BoxDecoration(
          color: s.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(40 * k),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Container(
                width: 52 * k, height: 52 * k,
                padding: EdgeInsets.all(9 * k),
                decoration: BoxDecoration(
                    color: s.primary, shape: BoxShape.circle),
                child: AppLogo(size: 34 * k, color: s.onPrimary),
              ),
              SizedBox(width: 14 * k),
              Text('LastStats', style: TextStyle(
                  fontSize: 24 * k, fontWeight: FontWeight.w800,
                  letterSpacing: -0.2, color: s.onSurface)),
              const Spacer(),
              if (badge != null && badge!.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 18 * k, vertical: 9 * k),
                  decoration: BoxDecoration(
                    color: accent == null ? s.primaryContainer : tone,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(badge!, style: TextStyle(
                      fontSize: 18 * k, fontWeight: FontWeight.w800,
                      color: accent == null
                          ? s.onPrimaryContainer
                          : ThemeData.estimateBrightnessForColor(tone) ==
                                  Brightness.dark
                              ? Colors.white : Colors.black)),
                ),
            ]),
            SizedBox(height: 28 * k),
            Text(title, style: TextStyle(
                fontSize: 40 * k, fontWeight: FontWeight.w800,
                height: 1.1, letterSpacing: -0.5, color: s.onSurface)),
            SizedBox(height: 26 * k),
            child,
            SizedBox(height: 24 * k),
            Row(children: [
              AppLogo(size: 20 * k, color: s.onSurfaceVariant),
              SizedBox(width: 10 * k),
              Flexible(child: Text(footer, style: TextStyle(
                  fontSize: 16 * k, fontWeight: FontWeight.w600,
                  color: s.onSurfaceVariant))),
            ]),
          ],
        ),
      ),
    );
  }
}
