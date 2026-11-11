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

import 'dart:ui' show lerpDouble, ImageFilter, TileMode;
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import '../app_state.dart';

// ── Haptics ────────────────────────────────────────────────────────────────
// One place for vibration. Respects the "haptic feedback" setting.
enum M3Haptic { selection, light, medium, heavy }

void m3Haptic([M3Haptic type = M3Haptic.selection]) {
  if (!hapticFeedbackNotifier.value) return;
  switch (type) {
    case M3Haptic.selection: HapticFeedback.selectionClick();
    case M3Haptic.light:     HapticFeedback.lightImpact();
    case M3Haptic.medium:    HapticFeedback.mediumImpact();
    case M3Haptic.heavy:     HapticFeedback.heavyImpact();
  }
}

// Gives a builder the "finger is down" state. Plug [setDown] into
// InkWell.onHighlightChanged so scrolling never counts as a press.
class M3PressBuilder extends StatefulWidget {
  const M3PressBuilder({super.key, required this.builder});
  final Widget Function(BuildContext context, bool down, ValueChanged<bool> setDown) builder;

  @override
  State<M3PressBuilder> createState() => _M3PressBuilderState();
}

class _M3PressBuilderState extends State<M3PressBuilder> {
  bool _down = false;

  void _set(bool v) {
    if (mounted && v != _down) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _down, _set);
}

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
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
      ecoModeActiveNotifier.value; // eco mode = no fancy motion

  /// Blur allowed? (user setting on, eco mode off)
  static bool get blurOn =>
      motionBlurNotifier.value && !ecoModeActiveNotifier.value;

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


// ── Page motion (rebuilt from scratch) ─────────────────────────────────────
// Why the old version "popped":
//  • a CurvedAnimation was rebuilt on every frame and the curve flipped
//    depending on the live status, so a quick back swipe jumped;
//  • the page content was repainted every frame under Opacity / blur;
//  • the page below could show a dark strip while moving.
// What this does instead:
//  • one State owns the curves (created once, direction-safe);
//  • the page content sits in a RepaintBoundary, so each frame only moves
//    a cached texture (no re-raster, no jank on the way back);
//  • the widget tree never changes shape while animating;
//  • the page below only drifts a little and is dimmed by a scrim, on a
//    solid surface colour, so no empty strip can show.
// Two styles, same engine:  slide (page → page)  and  rise (open a card).
// Reduced motion / eco mode → plain fade.
class _M3Page extends StatefulWidget {
  const _M3Page({
    required this.a,
    required this.s,
    required this.rise,
    required this.child,
    this.origin,
  });
  final Animation<double> a, s;
  final bool rise;
  final Widget child;
  final Rect? origin; // where the tapped item was (rise only)

  @override
  State<_M3Page> createState() => _M3PageState();
}

class _M3PageState extends State<_M3Page> {
  late CurvedAnimation _in, _out;
  late Widget _body; // cached, so a frame never rebuilds the page itself

  @override
  void initState() {
    super.initState();
    _bind();
    _body = RepaintBoundary(child: widget.child);
  }

  void _bind() {
    _in = CurvedAnimation(
        parent: widget.a,
        curve: M3Motion.emphasized,
        reverseCurve: Curves.easeInOutCubic);
    _out = CurvedAnimation(
        parent: widget.s,
        curve: M3Motion.emphasized,
        reverseCurve: Curves.easeInOutCubic);
  }

  @override
  void didUpdateWidget(_M3Page old) {
    super.didUpdateWidget(old);
    if (old.a != widget.a || old.s != widget.s) {
      _in.dispose();
      _out.dispose();
      _bind();
    }
    if (!identical(old.child, widget.child)) {
      _body = RepaintBoundary(child: widget.child);
    }
  }

  @override
  void dispose() {
    _in.dispose();
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final blur = M3Motion.blurOn;
    final rise = widget.rise;

    // Where a "rise" grows from: the tapped item when we know it.
    var align = Alignment.center;
    var startScale = 0.93;
    final o = widget.origin;
    if (rise && o != null && !o.isEmpty) {
      final sz = MediaQuery.sizeOf(context);
      if (o.width * o.height < sz.width * sz.height * 0.6) {
        align = Alignment(
          ((o.center.dx / sz.width) * 2 - 1).clamp(-1.0, 1.0),
          ((o.center.dy / sz.height) * 2 - 1).clamp(-1.0, 1.0),
        );
        startScale = 0.84;
      }
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_in, _out, widget.a]),
      child: ColoredBox(color: surface, child: _body),
      builder: (_, c) {
        final t = _in.value.clamp(0.0, 1.0); // this page, in
        final u = _out.value.clamp(0.0, 1.0); // covered by the next page
        final fade = const Interval(0.0, 0.4, curve: Curves.easeOut)
            .transform(widget.a.value.clamp(0.0, 1.0));
        final sigma = blur ? (rise ? 8.0 : 6.0) * (1 - t) : 0.0;

        Widget w = Stack(fit: StackFit.passthrough, children: [
          c!,
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                  color: Colors.black
                      .withValues(alpha: (rise ? 0.26 : 0.16) * u)),
            ),
          ),
        ]);

        w = ImageFiltered(
          enabled: sigma > 0.25,
          imageFilter: ImageFilter.blur(
              sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.clamp),
          child: w,
        );

        if (rise) {
          final r = (40.0 * (1 - t)) > (28.0 * u) ? 40.0 * (1 - t) : 28.0 * u;
          w = ClipRRect(
            borderRadius: BorderRadius.circular(r),
            clipBehavior: r > 0.5 ? Clip.antiAlias : Clip.none,
            child: w,
          );
          w = Transform.scale(
            scale: (startScale + (1 - startScale) * t) * (1 - 0.06 * u),
            alignment: align,
            child: FractionalTranslation(
                translation: Offset(0, 0.08 * (1 - t)), child: w),
          );
        } else {
          w = FractionalTranslation(
              translation: Offset(0.28 * (1 - t) - 0.12 * u, 0), child: w);
        }
        return Opacity(opacity: fade, child: w);
      },
    );
  }
}

Widget m3SlideTransition(BuildContext context, Animation<double> a,
    Animation<double> s, Widget child) {
  if (M3Motion.reduced(context)) {
    return FadeTransition(opacity: a, child: child);
  }
  return _M3Page(a: a, s: s, rise: false, child: child);
}

/// Open a detail page (artist / album / track / friend) and come back.
/// The page rises (grows from the tapped item when known), corners flatten,
/// sharpens from a soft blur; the page behind shrinks a bit and dims.
Widget m3RiseTransition(BuildContext context, Animation<double> a,
    Animation<double> s, Widget child,
    {Rect? origin}) {
  if (M3Motion.reduced(context)) {
    return FadeTransition(opacity: a, child: child);
  }
  return _M3Page(a: a, s: s, rise: true, origin: origin, child: child);
}

/// Content arriving (cards, charts, loaded data): rises, grows from a
/// slightly smaller size and sharpens from a blur. [t] runs 0 → 1.
Widget m3Reveal(BuildContext context, Animation<double> t, Widget child) {
  if (M3Motion.reduced(context)) return child;
  final k = CurvedAnimation(parent: t, curve: M3Motion.spatialDefault);
  return AnimatedBuilder(
    animation: k,
    child: child,
    builder: (_, c) {
      final v = t.value.clamp(0.0, 1.0);
      final sigma = (!M3Motion.blurOn || v >= 1) ? 0.0 : 8.0 * (1 - v);
      return Opacity(
        opacity: Curves.easeOut.transform((v * 2).clamp(0.0, 1.0)),
        child: ImageFiltered(
          enabled: sigma > 0.3,
          imageFilter: ImageFilter.blur(
              sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
          child: Transform.translate(
            offset: Offset(0, 36 * (1 - k.value)),
            child: Transform.scale(scale: 0.92 + 0.08 * k.value, child: c),
          ),
        ),
      );
    },
  );
}

class M3RiseRoute<T> extends PageRouteBuilder<T> {
  M3RiseRoute({required WidgetBuilder builder, Rect? origin})
      : super(
          transitionDuration: const Duration(milliseconds: 480),
          reverseTransitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (context, _, _) => builder(context),
          transitionsBuilder: (context, a, s, child) =>
              m3RiseTransition(context, a, s, child, origin: origin),
        );
}

class M3SlideRoute<T> extends PageRouteBuilder<T> {
  M3SlideRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (context, _, _) => builder(context),
          transitionsBuilder: (context, a, s, child) =>
              m3SlideTransition(context, a, s, child),
        );
}

// ── Forward / backward (normal navigation) ─────────────────────────────────
// Rise + fade with a spatial spring. The old page stays solid underneath.
class M3PageTransitionsBuilder extends PageTransitionsBuilder {
  const M3PageTransitionsBuilder();

  @override
  Duration get transitionDuration => M3Motion.spatialDefaultDuration;

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 350);

  // The page underneath stays still and solid (no fade), so nothing
  // behind it (for example the home screen) shows through while animating.
  @override
  get delegatedTransition => null;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return m3SlideTransition(context, animation, secondaryAnimation, child);
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
                  color: Theme.of(context).colorScheme.surface
                      .withValues(alpha: 0.55 * raw),
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
    duration: const Duration(milliseconds: 340),
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
      _c.value = 0; // set BEFORE this frame builds: no one-frame flash
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Tabs cross-fade with a small directional slide and a soft blur.
// Rules that keep it pop-free:
//  • every tab keeps the SAME wrapper chain whether shown or hidden, so
//    nothing is mounted / unmounted while animating (state is kept);
//  • the incoming tab is on screen from the very first frame (never
//    Offstage while it fades in), so it is never laid out "late";
//  • the old tab fades out while the new one fades in (no empty gap);
//  • each tab sits in a RepaintBoundary: frames only move cached layers.
  Widget _item(int i, double t, bool reduce, bool blur) {
    final isCur = i == _current;
    final isPrev = i == _previous && t < 1.0;
    final dir = _current >= _previous ? 1.0 : -1.0;
    double opacity = 0, scale = 1, dx = 0, sigma = 0;
    if (isCur) {
      final k = M3Motion.emphasizedDecelerate.transform(t);
      opacity = const Interval(0.1, 0.8, curve: Curves.easeOut).transform(t);
      if (!reduce) {
        scale = 0.98 + 0.02 * k;
        dx = dir * 24 * (1 - k);
        sigma = blur ? 5 * (1 - k) : 0;
      }
    } else if (isPrev) {
      final k = const Interval(0.0, 0.45, curve: Curves.easeIn).transform(t);
      opacity = 1.0 - k;
      if (!reduce) {
        dx = -dir * 16 * k;
        sigma = blur ? 4 * k : 0;
      }
    }
    return Offstage(
      offstage: !isCur && !isPrev,
      child: IgnorePointer(
        ignoring: !isCur,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: ImageFiltered(
            enabled: sigma > 0.25,
            imageFilter: ImageFilter.blur(
                sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.clamp),
            child: Transform.translate(
              offset: Offset(dx, 0),
              child: Transform.scale(
                scale: scale,
                child: RepaintBoundary(child: widget.children[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduce = M3Motion.reduced(context);
    final blur = !reduce && M3Motion.blurOn;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Stack(
        fit: StackFit.expand,
        children: [
          for (int i = 0; i < widget.children.length; i++)
            KeyedSubtree(
              key: ValueKey<int>(i),
              child: _item(i, reduce ? 1.0 : _c.value, reduce, blur),
            ),
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
    this.duration = const Duration(milliseconds: 450),
    this.child,
  });

  final Duration duration;
  final Widget?  child;

  // Loading → content: old content sinks and softens, new content rises
  // and sharpens (see m3Reveal). Not a plain cross-fade.
  static Widget _fade(Widget child, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final leaving = animation.status == AnimationStatus.reverse;
        if (!leaving) return m3Reveal(context, animation, child!);
        final v = animation.value;
        return Opacity(
          opacity: const Interval(0.5, 1.0).transform(v),
          child: Transform.scale(scale: 0.97 + 0.03 * v, child: child),
        );
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


// ── Shared axis (Y) route ──────────────────────────────────────────────────
// For child pages of the same flow (for example account level -> level
// history). New page rises and fades in with a spatial spring, the old one
// fades out and shrinks a little. Going back is the reverse, but faster.
class M3SharedAxisRoute<T> extends M3SlideRoute<T> {
  M3SharedAxisRoute({required super.builder});
}


// ── Letter-by-letter blur reveal (titles, recap text) ──────────────────────
// Each letter sharpens from a blur and rises, one after the other.
// [t] runs 0 -> 1. Without blur (setting off / eco mode) it is a plain
// letter fade, and in reduced motion the text is shown immediately.
class M3BlurText extends StatelessWidget {
  const M3BlurText(this.text,
      {super.key, required this.t, this.style, this.align = TextAlign.center});
  final String text;
  final Animation<double> t;
  final TextStyle? style;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    if (M3Motion.reduced(context)) {
      return Text(text, style: style, textAlign: align);
    }
    final words = text.split(' ');
    final total = text.length.clamp(1, 80);
    final blur = M3Motion.blurOn;
    final wrapAlign = align == TextAlign.center
        ? WrapAlignment.center
        : (align == TextAlign.end || align == TextAlign.right)
            ? WrapAlignment.end
            : WrapAlignment.start;
    return AnimatedBuilder(
      animation: t,
      builder: (_, _) {
        var n = 0;
        return Wrap(
          alignment: wrapAlign,
          children: [
            for (final w in words)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (final r in w.runes)
                    () {
                      final i = n++;
                      final a = (i / total) * 0.55;
                      final k = ((t.value - a) / 0.45).clamp(0.0, 1.0);
                      final e = Curves.easeOutCubic.transform(k);
                      final sg = blur ? 8.0 * (1 - e) : 0.0;
                      return Opacity(
                        opacity: e,
                        child: ImageFiltered(
                          enabled: sg > 0.3,
                          imageFilter: ImageFilter.blur(
                              sigmaX: sg, sigmaY: sg, tileMode: TileMode.decal),
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - e)),
                            child: Text(String.fromCharCode(r), style: style),
                          ),
                        ),
                      );
                    }(),
                ]),
              ),
          ],
        );
      },
    );
  }
}
