// Solid bar drawn under the system status bar (time, battery, wifi...) that
// slides in from the top, but only once the content below has been scrolled.
// Wrap any vertical scrollable (or a stack of pages) with it. [resetToken]
// hides the bar again when it changes (e.g. the selected tab).
import 'package:flutter/material.dart';
import '../theme/m3_motion.dart';

class ScrollStatusBarHost extends StatefulWidget {
  final Widget child;
  final Color color;
  final Object? resetToken;
  final double threshold;
  final ValueChanged<bool>? onVisibleChanged;
  const ScrollStatusBarHost({
    super.key,
    required this.child,
    required this.color,
    this.resetToken,
    this.threshold = 24,
    this.onVisibleChanged,
  });

  @override
  State<ScrollStatusBarHost> createState() => _ScrollStatusBarHostState();
}

class _ScrollStatusBarHostState extends State<ScrollStatusBarHost> {
  bool _visible = false;

  void _set(bool v) {
    if (v == _visible) return;
    setState(() => _visible = v);
    widget.onVisibleChanged?.call(v);
  }

  @override
  void didUpdateWidget(covariant ScrollStatusBarHost old) {
    super.didUpdateWidget(old);
    if (old.resetToken != widget.resetToken && _visible) {
      // Post-frame: the callback may call setState on a parent.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _set(false);
      });
    }
  }

  bool _onScroll(ScrollNotification n) {
    // Only the main vertical scrollable (ignore nested horizontal lists).
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    _set(n.metrics.pixels > widget.threshold);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Stack(
      fit: StackFit.expand,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: widget.child,
        ),
        Positioned(
          top: 0, left: 0, right: 0, height: topPad,
          child: IgnorePointer(
            child: AnimatedSlide(
              offset: _visible ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 320),
              curve: M3Motion.emphasizedDecelerate,
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: ColoredBox(color: widget.color),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
