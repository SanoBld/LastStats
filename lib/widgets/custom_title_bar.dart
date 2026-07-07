// lib/widgets/custom_title_bar.dart
// ══════════════════════════════════════════════════════════════════════════
//  Custom, theme-matched title bar for Windows/Linux desktop builds.
//  Replaces the native OS caption buttons with ones styled from the app's
//  own ColorScheme, so it stays consistent with Material You / Nothing OS /
//  OLED themes instead of standing out as a generic Windows title bar.
//  No-op (returns child untouched) on mobile, web, and macOS.
// ══════════════════════════════════════════════════════════════════════════

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

bool get _isDesktopFrameless =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux);

class DesktopTitleBarShell extends StatelessWidget {
  final Widget child;
  const DesktopTitleBarShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!_isDesktopFrameless) return child;
    return Column(children: [
      const _CustomTitleBar(),
      Expanded(child: child),
    ]);
  }
}

class _CustomTitleBar extends StatefulWidget {
  const _CustomTitleBar();

  @override
  State<_CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<_CustomTitleBar> with WindowListener {
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.isMaximized().then((v) {
      if (mounted) setState(() => _maximized = v);
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize()   => setState(() => _maximized = true);
  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  Future<void> _toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: Container(
      height: 36,
      color: scheme.surfaceContainer,
      child: Row(children: [
        // ── Drag region + app name ────────────────────────────────────────
        Expanded(
          child: DragToMoveArea(
            child: GestureDetector(
              onDoubleTap: _toggleMaximize,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(children: [
                  Icon(Icons.graphic_eq_rounded, size: 15, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text('LastStats',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      )),
                ]),
              ),
            ),
          ),
        ),
        // ── Caption buttons, styled with the app theme ────────────────────
        _CaptionButton(
          icon: Icons.remove_rounded,
          onTap: () => windowManager.minimize(),
          scheme: scheme,
        ),
        _CaptionButton(
          icon: _maximized ? Icons.filter_none_rounded : Icons.crop_square_rounded,
          iconSize: _maximized ? 13 : 14,
          onTap: _toggleMaximize,
          scheme: scheme,
        ),
        _CaptionButton(
          icon: Icons.close_rounded,
          onTap: () => windowManager.close(),
          scheme: scheme,
          isClose: true,
        ),
      ]),
    ));
  }
}

class _CaptionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final bool isClose;
  final double iconSize;

  const _CaptionButton({
    required this.icon,
    required this.onTap,
    required this.scheme,
    this.isClose = false,
    this.iconSize = 15,
  });

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor = widget.isClose
        ? const Color(0xFFE81123)
        : widget.scheme.onSurface.withValues(alpha: 0.08);
    final iconColor = _hover && widget.isClose
        ? Colors.white
        : widget.scheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 46,
          height: 36,
          color: _hover ? hoverColor : Colors.transparent,
          alignment: Alignment.center,
          child: Icon(widget.icon, size: widget.iconSize, color: iconColor),
        ),
      ),
    );
  }
}