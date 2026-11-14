// lib/widgets/m3_popup_menu.dart
// "Bubble" options menu: opens next to the pressed element, grows from the
// nearest corner (scale + fade), actions are connected rounded blocks
// (big outer corners 20, small inner corners 5, 2 px gap).
// Design idea inspired by Metrolist (GPL-3.0).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/extra_strings.dart';
import '../theme/m3_motion.dart';
import 'brand_icon.dart';

class M3MenuItem {
  final String label;
  final IconData icon;
  final String? asset; // brand logo (SVG) shown instead of [icon]
  final VoidCallback? onTap;
  final bool selected;
  final bool destructive;
  const M3MenuItem({
    required this.label,
    required this.icon,
    this.asset,
    this.onTap,
    this.selected = false,
    this.destructive = false,
  });
}

/// [context] = element the bubble is attached to. [at] = pointer position
/// (right click on PC) used instead of the element.
Future<void> showM3Menu(
  BuildContext context, {
  required List<List<M3MenuItem>> groups,
  Offset? at,
}) {
  final clean = [for (final g in groups) if (g.isNotEmpty) g];
  if (clean.isEmpty) return Future.value();
  Rect anchor;
  if (at != null) {
    anchor = Rect.fromLTWH(at.dx, at.dy, 1, 1);
  } else {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      anchor = box.localToGlobal(Offset.zero) & box.size;
    } else {
      final s = MediaQuery.sizeOf(context);
      anchor = Rect.fromLTWH(s.width / 2, s.height / 2, 1, 1);
    }
  }
  m3Haptic(M3Haptic.medium);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.12),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim, _) => _MenuLayer(anchor: anchor, groups: clean, anim: anim),
    transitionBuilder: (ctx, anim, _, child) => child,
  );
}

class _MenuLayer extends StatelessWidget {
  final Rect anchor;
  final List<List<M3MenuItem>> groups;
  final Animation<double> anim;
  const _MenuLayer({required this.anchor, required this.groups, required this.anim});

  static const _itemH = 48.0;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final width = (size.width - 24).clamp(180.0, 260.0);
    final count = groups.fold<int>(0, (a, g) => a + g.length);
    final height = count * _itemH + (count - groups.length) * 2 + (groups.length - 1) * 8 + 12;

    final rightHalf = anchor.center.dx > size.width / 2;
    var left = rightHalf ? anchor.right - width : anchor.left;
    left = left.clamp(12.0, (size.width - width - 12).clamp(12.0, double.infinity));

    final maxBottom = size.height - mq.padding.bottom - 12;
    var below = true;
    var top = anchor.bottom + 6;
    if (top + height > maxBottom) {
      below = false;
      top = anchor.top - height - 6;
    }
    top = top.clamp(mq.padding.top + 12, (maxBottom - height).clamp(mq.padding.top + 12, double.infinity));

    final curved = CurvedAnimation(
        parent: anim, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final reduced = M3Motion.reduced(context);
    final scheme = Theme.of(context).colorScheme;

    Widget menu = Material(
      color: scheme.surfaceContainerLow,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: SizedBox(
          width: width - 12,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (var g = 0; g < groups.length; g++) ...[
              if (g > 0) const SizedBox(height: 8),
              _Group(items: groups[g]),
            ],
          ]),
        ),
      ),
    );

    menu = FadeTransition(
      opacity: curved,
      child: reduced
          ? menu
          : ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
              alignment: Alignment(rightHalf ? 1 : -1, below ? -1 : 1),
              child: menu,
            ),
    );

    return Stack(children: [
      Positioned(left: left, top: top, width: width, child: menu),
    ]);
  }
}

class _Group extends StatelessWidget {
  final List<M3MenuItem> items;
  const _Group({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(height: 2),
        _Row(item: items[i], index: i, count: items.length),
      ],
    ]);
  }
}

class _Row extends StatelessWidget {
  final M3MenuItem item;
  final int index, count;
  const _Row({required this.item, required this.index, required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const big = Radius.circular(20), small = Radius.circular(5);
    final shape = BorderRadius.only(
      topLeft: index == 0 ? big : small,
      topRight: index == 0 ? big : small,
      bottomLeft: index == count - 1 ? big : small,
      bottomRight: index == count - 1 ? big : small,
    );
    final fg = item.destructive
        ? scheme.error
        : item.selected ? scheme.onPrimaryContainer : scheme.onSurface;
    final bg = item.selected ? scheme.primaryContainer : scheme.surfaceContainerHigh;
    return Material(
      color: bg,
      borderRadius: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.onTap == null
            ? null
            : () {
                m3Haptic(M3Haptic.selection);
                final cb = item.onTap!;
                Navigator.of(context).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) => cb());
              },
        child: SizedBox(
          height: _MenuLayer._itemH,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              item.asset != null
                  ? BrandIcon(item.asset!, item.icon, size: 20, color: fg)
                  : Icon(item.icon, size: 20, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: fg, fontWeight: FontWeight.w600)),
              ),
              if (item.selected) Icon(Icons.check_rounded, size: 18, color: fg),
            ]),
          ),
        ),
      ),
    );
  }
}

// Ready-made menu for a track / album / artist.
Future<void> showTrackMenu(
  BuildContext context, {
  required String name,
  required String artist,
  Offset? at,
  VoidCallback? onAddToFolder,
  VoidCallback? onSelect, // starts multi-select (lists that support it)
  String type = 'tracks', // 'tracks' | 'albums' | 'artists'
}) {
  final isArtist = type == 'artists';
  String enc(String v) => Uri.encodeComponent(v);
  final q = enc((isArtist ? name : '$artist $name').trim());
  final lastfm = isArtist
      ? 'https://www.last.fm/music/${enc(name)}'
      : artist.isEmpty
          ? 'https://www.last.fm/search?q=${enc(name)}'
          : type == 'albums'
              ? 'https://www.last.fm/music/${enc(artist)}/${enc(name)}'
              : 'https://www.last.fm/music/${enc(artist)}/_/${enc(name)}';
  Future<void> open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  final messenger = ScaffoldMessenger.maybeOf(context);
  void copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    messenger?.showSnackBar(SnackBar(
      content: Text(tx('menu_copied')),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  return showM3Menu(context, at: at, groups: [
    if (onAddToFolder != null || onSelect != null)
      [
        if (onSelect != null)
          M3MenuItem(label: tx('menu_select'), icon: Icons.checklist_rounded, onTap: onSelect),
        if (onAddToFolder != null)
          M3MenuItem(label: tx('menu_add_folder'), icon: Icons.create_new_folder_rounded, onTap: onAddToFolder),
      ],
    [
      M3MenuItem(label: 'Last.fm', icon: Icons.open_in_new_rounded,
          asset: 'assets/icons/lastfm.svg', onTap: () => open(lastfm)),
      M3MenuItem(label: 'Spotify', icon: Icons.open_in_new_rounded,
          asset: 'assets/icons/spotify.svg', onTap: () => open('https://open.spotify.com/search/$q')),
      M3MenuItem(label: 'YouTube Music', icon: Icons.open_in_new_rounded,
          asset: 'assets/icons/ytmusic.svg', onTap: () => open('https://music.youtube.com/search?q=$q')),
      M3MenuItem(label: 'Apple Music', icon: Icons.open_in_new_rounded,
          asset: 'assets/icons/applemusic.svg', onTap: () => open('https://music.apple.com/search?term=$q')),
      M3MenuItem(label: 'Deezer', icon: Icons.open_in_new_rounded,
          asset: 'assets/icons/deezer.svg', onTap: () => open('https://www.deezer.com/search/$q')),
    ],
    [
      M3MenuItem(label: tx('menu_copy_title'), icon: Icons.content_copy_rounded, onTap: () => copy(name)),
      if (artist.isNotEmpty && !isArtist)
        M3MenuItem(label: tx('menu_copy_both'), icon: Icons.copy_all_rounded, onTap: () => copy('$artist – $name')),
    ],
  ]);
}
