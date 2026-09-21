// lib/theme/m3_motion.dart
// ══════════════════════════════════════════════════════════════════════════
//  Material 3 motion, in one place.
//
//  • M3Motion              → easing curves + durations
//  • M3PageTransitionsBuilder → normal forward / backward page transition
//  • M3ContainerRoute      → "container transform" (item grows into a page)
//  • M3FadeThroughStack    → top level tabs (quick fade, no overlap)
//  • M3Switcher            → AnimatedSwitcher with clean fades
//
//  Reduced motion: when the system asks for less animation, everything
//  here becomes a simple fade (no sliding, no scaling).
// ══════════════════════════════════════════════════════════════════════════

import 'dart:ui' show lerpDouble;
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

class M3Motion {
  M3Motion._();

  // Easing (Material 3)
  static const Curve emphasized           = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
  static const Curve standard             = Cubic(0.2, 0.0, 0.0, 1.0);

  // Motion physics (springs), converted to curves as Material recommends
  // when real springs are not available (Flutter). "Spatial" = moves, size,
  // shape (a little overshoot). "Effects" = color, opacity (no overshoot).
  static const Curve spatialFast    = Cubic(0.42, 1.67, 0.21, 0.90); // 350 ms
  static const Curve spatialDefault = Cubic(0.38, 1.21, 0.22, 1.00); // 500 ms
  static const Curve spatialSlow    = Cubic(0.39, 1.29, 0.35, 0.98); // 650 ms
  static const Curve effectsFast    = Cubic(0.31, 0.94, 0.34, 1.00); // 150 ms
  static const Curve effectsDefault = Cubic(0.34, 0.80, 0.34, 1.00); // 200 ms
  static const Curve effectsSlow    = Cubic(0.34, 0.88, 0.34, 1.00); // 300 ms

  static const Duration spatialFastDuration    = Duration(milliseconds: 350);
  static const Duration spatialDefaultDuration = Duration(milliseconds: 500);
  static const Duration effectsFastDuration    = Duration(milliseconds: 150);
  static const Duration effectsDefaultDuration = Duration(milliseconds: 200);

  // Durations
  static const Duration short  = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long   = Duration(milliseconds: 450);

  /// True when the user turned on "reduce animations".
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Position of a widget, in the coordinates of the app overlay.
  /// Used as the start of a container transform. Returns null if unknown.
  static Rect? originOf(BuildContext context) {
    try {
      final ro = context.findRenderObject();
      if (ro is! RenderBox || !ro.attached || !ro.hasSize) return null;
      final overlayRo =
          Navigator.of(context).overlay?.context.findRenderObject();
      final topLeft = ro.localToGlobal(
        Offset.zero,
        ancestor: overlayRo is RenderBox ? overlayRo : null,
      );
      return topLeft & ro.size;
    } catch (_) {
      return null;
    }
  }
}

// ── Forward / backward (normal navigation) ─────────────────────────────────
// Uses the Material 3 default "fade forwards" transition.
class M3PageTransitionsBuilder extends PageTransitionsBuilder {
  const M3PageTransitionsBuilder();

  static const FadeForwardsPageTransitionsBuilder _base =
      FadeForwardsPageTransitionsBuilder();

  @override
  Duration get transitionDuration => _base.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _base.reverseTransitionDuration;

  @override
  get delegatedTransition => _base.delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Reduced motion → only a subtle fade.
    if (M3Motion.reduced(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    return _base.buildTransitions<T>(
        route, context, animation, secondaryAnimation, child);
  }
}

/// Put this in ThemeData(pageTransitionsTheme: kM3PageTransitions).
const PageTransitionsTheme kM3PageTransitions = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: M3PageTransitionsBuilder(),
    TargetPlatform.fuchsia: M3PageTransitionsBuilder(),
    TargetPlatform.windows: M3PageTransitionsBuilder(),
    TargetPlatform.linux:   M3PageTransitionsBuilder(),
    TargetPlatform.macOS:   M3PageTransitionsBuilder(),
    TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
  },
);

// ── Container transform ────────────────────────────────────────────────────
// The tapped item grows into the full page. Use it for "hero" moments
// (open an artist / album / track from a list), not for deep navigation.
class M3ContainerRoute<T> extends PageRoute<T> {
  M3ContainerRoute({
    required this.builder,
    this.origin,
    this.originRadius = 16,
    this.color,
  });

  final WidgetBuilder builder;
  final Rect?         origin;
  final double        originRadius;
  final Color?        color;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 450);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 350);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: builder(context),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // Reduced motion → plain fade.
    if (M3Motion.reduced(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    final fill = color ?? Theme.of(context).colorScheme.surface;

    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final full = Offset.zero & size;

      // If we don't know the tapped item (or it is huge), start from a
      // small box in the middle so it still looks like a "grow".
      Rect start = origin ?? Rect.zero;
      final tooBig = start.width * start.height > size.width * size.height * 0.7;
      if (origin == null || tooBig || start.isEmpty) {
        start = Rect.fromCenter(
          center: full.center,
          width:  size.width * 0.6,
          height: size.height * 0.3,
        );
      }

      return AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, page) {
          final raw = animation.value.clamp(0.0, 1.0);
          final v   = M3Motion.emphasized.transform(raw);
          final rect   = Rect.lerp(start, full, v)!;
          final radius = lerpDouble(originRadius, 0, v)!;
          // Page content fades in after the container is mostly open,
          // and fades out first when closing (no messy cross fade).
          final contentOpacity =
              const Interval(0.3, 0.75, curve: Curves.easeOut).transform(raw);

          return Stack(children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.32 * raw),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: rect,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: ColoredBox(
                  color: fill,
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minWidth:  size.width,
                    maxWidth:  size.width,
                    minHeight: size.height,
                    maxHeight: size.height,
                    child: Opacity(opacity: contentOpacity, child: page),
                  ),
                ),
              ),
            ),
          ]);
        },
      );
    });
  }
}

// ── Top level destinations (bottom bar / rail) ─────────────────────────────
// Old page fades out first, then the new page fades in. No overlap.
// All pages stay alive so they keep their state.
class M3FadeThroughStack extends StatefulWidget {
  const M3FadeThroughStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int          index;
  final List<Widget> children;

  @override
  State<M3FadeThroughStack> createState() => _M3FadeThroughStackState();
}

class _M3FadeThroughStackState extends State<M3FadeThroughStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1.0,
  );
  late int _current = widget.index;
  int _previous = -1;

  @override
  void didUpdateWidget(M3FadeThroughStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _previous = old.index;
      _current  = widget.index;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _item(int i, double t, bool reduce) {
    double opacity = 0;
    double scale   = 1;
    if (i == _current) {
      final k = const Interval(0.35, 1.0, curve: M3Motion.emphasizedDecelerate)
          .transform(t);
      opacity = k;
      scale   = reduce ? 1.0 : 0.96 + 0.04 * k;
    } else if (i == _previous && t < 1.0) {
      opacity =
          1.0 - const Interval(0.0, 0.35, curve: Curves.easeIn).transform(t);
    }
    return Offstage(
      offstage: opacity <= 0.0,
      child: IgnorePointer(
        ignoring: i != _current,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: widget.children[i]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduce = M3Motion.reduced(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Stack(
        children: [
          for (int i = 0; i < widget.children.length; i++)
            _item(i, reduce ? 1.0 : _c.value, reduce),
        ],
      ),
    );
  }
}

// ── Clean fade switcher ────────────────────────────────────────────────────
// Like AnimatedSwitcher, but the old child is fully gone before the new
// one appears (no half transparent overlap).
class M3Switcher extends StatelessWidget {
  const M3Switcher({
    super.key,
    this.duration = const Duration(milliseconds: 300),
    this.child,
  });

  final Duration duration;
  final Widget?  child;

  static Widget _fade(Widget child, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final leaving = animation.status == AnimationStatus.reverse;
        final v = animation.value;
        final opacity = leaving
            ? const Interval(0.65, 1.0).transform(v)
            : const Interval(0.35, 1.0, curve: M3Motion.effectsDefault).transform(v);
        return Opacity(opacity: opacity, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: M3Motion.reduced(context) ? M3Motion.short : duration,
      switchInCurve:  Curves.linear,
      switchOutCurve: Curves.linear,
      transitionBuilder: _fade,
      child: child,
    );
  }
}

// ── One-time flows (setup → onboarding → home) ─────────────────────────────
// Old page fades out first, then the new page fades in. No overlap.
class M3FadeThroughRoute<T> extends PageRouteBuilder<T> {
  M3FadeThroughRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, _, _) => builder(context),
          transitionsBuilder: (context, animation, secondary, child) {
            final incoming = animation.drive(CurveTween(
                curve: const Interval(0.35, 1.0, curve: Curves.easeOut)));
            final outgoing = ReverseAnimation(secondary.drive(CurveTween(
                curve: const Interval(0.0, 0.35, curve: Curves.easeIn))));
            return FadeTransition(
              opacity: outgoing,
              child: FadeTransition(opacity: incoming, child: child),
            );
          },
        );
}
