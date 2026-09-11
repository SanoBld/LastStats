// ignore_for_file: unused_import
part of 'home_screen.dart';
// Story-style shared design tokens (typography, radii, motion) — see
// lib/theme/story_style.dart. Applied here so every screen using these
// shared widgets automatically matches the recap story's look.

// ── Small helper: capped stagger delay for long lists ────────────────────────
// Using `i * 35ms` directly on a 200-item list would mean the last item
// waits 7 seconds to appear, so we cap how far the delay grows.
Duration _staggerDelay(int index) =>
    Duration(milliseconds: index.clamp(0, 10) * 35);

// ── Reusable entrance animation: fade + subtle upward slide ──────────────────
// Wrap any list item with this to get a gentle slide-in on first render.
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  // When true, the entrance is skipped entirely and the child appears
  // already fully in place (used for "play once per app session" spots,
  // e.g. the dashboard, so re-visiting the tab doesn't replay it).
  final bool skipAnimation;
  const _FadeSlideIn({
    required this.child,
    this.delay         = Duration.zero,
    this.skipAnimation = false,
  }) : duration = const Duration(milliseconds: 350);

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: widget.duration);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    if (widget.skipAnimation) {
      _ctrl.value = 1.0; // already "arrived" — no fade/slide to play
    } else if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () { if (mounted) _ctrl.forward(); });
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child:   SlideTransition(position: _slide, child: widget.child),
  );
}

// ── Reusable press animation: small scale-down bounce on tap ─────────────────
// Wrap any tappable card/button in this to give it a "squishy", tactile feel
// instead of a flat InkWell tap. Doesnt eat the tap, it just forward it.
class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _PressScale({
    required this.child,
    this.onTap,
  });

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  void _setDown(bool v) { if (mounted) setState(() => _down = v); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown:   widget.onTap == null ? null : (_) => _setDown(true),
      onTapUp:     widget.onTap == null ? null : (_) => _setDown(false),
      onTapCancel: widget.onTap == null ? null : () => _setDown(false),
      onTap:       widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ── Pulsing status dot (used in NowPlayingCard and friend cards) ──────────────
class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  const _PulsingDot({required this.color, this.size = 7});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.75, end: 1.25)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: Container(
      width:  widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
        // Soft outer glow that breathes with the scale
        boxShadow: [
          BoxShadow(
            color:      widget.color.withValues(alpha: 0.55),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
    ),
  );
}

/// Widget d'image intelligent avec résolution asynchrone.
/// Converti en StatefulWidget pour mémoriser le Future de résolution :
/// le resolver n'est appelé qu'une seule fois (ou si l'URL source change),
/// ce qui évite les clignotements lors des rebuilds du parent (ex: refresh).
class _SmartImage extends StatefulWidget {
  final String? initialUrl;
  final Future<String> Function() resolver;
  final double size, borderRadius;
  const _SmartImage({required this.resolver, required this.size,
      required this.borderRadius, this.initialUrl});

  static const _ph = '2a96cbd8b46e442fc41c2b86b821562f';

  @override
  State<_SmartImage> createState() => _SmartImageState();
}

class _SmartImageState extends State<_SmartImage> {
  Future<String>? _future;
  String?         _resolvedUrl;   // URL déjà résolue → pas de FutureBuilder
  String?         _lastInitialUrl;

  bool get _needsResolve =>
      widget.initialUrl == null ||
      widget.initialUrl!.isEmpty ||
      widget.initialUrl!.contains(_SmartImage._ph);

  @override
  void initState() {
    super.initState();
    _lastInitialUrl = widget.initialUrl;
    if (!_needsResolve) {
      _resolvedUrl = widget.initialUrl;
    } else {
      _future = widget.resolver();
    }
  }

  @override
  void didUpdateWidget(_SmartImage old) {
    super.didUpdateWidget(old);
    // Relancer uniquement si l'URL source a changé (piste différente)
    if (widget.initialUrl != _lastInitialUrl) {
      _lastInitialUrl = widget.initialUrl;
      _resolvedUrl    = null;
      if (!_needsResolve) {
        _resolvedUrl = widget.initialUrl;
        _future      = null;
      } else {
        _future = widget.resolver();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // URL already available — skip FutureBuilder entirely
    if (_resolvedUrl != null && _resolvedUrl!.isNotEmpty) {
      return _img(_resolvedUrl!, scheme);
    }
    if (!_needsResolve) {
      return _img(widget.initialUrl!, scheme);
    }

    return FutureBuilder<String>(
      future: _future,
      builder: (_, snap) {
        final Widget child;
        if (snap.connectionState != ConnectionState.done) {
          child = _loading(scheme);
        } else {
          final url = snap.data ?? '';
          // Persist result so future rebuilds skip the FutureBuilder
          if (url.isNotEmpty && _resolvedUrl == null) _resolvedUrl = url;
          child = url.isEmpty ? _fallback(scheme) : _img(url, scheme);
        }
        // Smooth fade between the loading placeholder and the resolved image
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
          child: KeyedSubtree(
            key: ValueKey(snap.connectionState == ConnectionState.done
                ? (snap.data ?? 'fallback')
                : 'loading'),
            child: child,
          ),
        );
      },
    );
  }

  Widget _img(String url, ColorScheme s) {
    // Decode at display resolution (x devicePixelRatio) instead of the
    // source's full size — big RAM saving for lists of small avatars,
    // no visible quality loss since it still matches screen pixels.
    final px = (widget.size * MediaQuery.of(context).devicePixelRatio).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Image.network(url, width: widget.size, height: widget.size, fit: BoxFit.cover,
          cacheWidth: px, cacheHeight: px,
          errorBuilder: (_, _, _) => _fallback(s)));
  }

  Widget _loading(ColorScheme s) => ClipRRect(
    borderRadius: BorderRadius.circular(widget.borderRadius),
    child: Container(width: widget.size, height: widget.size,
      color: s.surfaceContainerHighest,
      child: Center(child: SizedBox(
        width:  widget.size * 0.4,
        height: widget.size * 0.4,
        child: CircularProgressIndicator(
            strokeWidth: 1.5, color: s.primary.withValues(alpha: 0.5))))));

  Widget _fallback(ColorScheme s) => ClipRRect(
    borderRadius: BorderRadius.circular(widget.borderRadius),
    child: Container(width: widget.size, height: widget.size,
      color: s.surfaceContainerHighest,
      child: Icon(Icons.music_note_rounded,
          color: s.onSurfaceVariant, size: widget.size * 0.5)));
}

class _SectionHeader extends StatelessWidget {
  final String title; final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      Icon(icon, size: 18, color: scheme.primary),
      const SizedBox(width: 8),
      Text(title, style: AppText.itemTitle.copyWith(color: scheme.onSurface)),
      const SizedBox(width: 10),
      Expanded(
        child: Divider(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
          thickness: 1,
        ),
      ),
    ]);
  }
}

class _ItemTile extends StatelessWidget {
  final String name, sub, imageUrl, rank;
  final Future<String>? imageFuture;
  final String? plays;
  // Optional "save to folder" button. When set, a folder icon shows on the
  // right; folderEmojis (if any) are shown as a small strip under sub, so
  // the user can see at a glance which folder(s) this item is saved in.
  final VoidCallback? onAssign;
  final List<String>  folderEmojis;
  const _ItemTile({required this.name, required this.sub, required this.imageUrl,
      required this.rank, this.imageFuture, this.plays, this.onAssign,
      this.folderEmojis = const []});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: AppRadius.mdR,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(children: [
          SizedBox(width: 28, child: Text(rank, textAlign: TextAlign.center,
              style: AppText.label.copyWith(color: scheme.onSurfaceVariant))),
          const SizedBox(width: 8),
          _SmartImage(size: 48, borderRadius: AppRadius.sm, initialUrl: imageUrl,
              resolver: imageFuture != null ? () => imageFuture! : () => Future.value('')),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppText.itemTitle.copyWith(fontSize: 14, color: scheme.onSurface)),
            Row(children: [
              if (sub.isNotEmpty) Flexible(child: Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: AppText.label.copyWith(color: scheme.onSurfaceVariant))),
              if (folderEmojis.isNotEmpty) Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(folderEmojis.take(3).join(''), style: const TextStyle(fontSize: 11)),
              ),
            ]),
          ])),
          if (plays != null) Padding(padding: const EdgeInsets.only(left: 8),
            child: Text(plays!, style: AppText.body.copyWith(color: scheme.primary))),
          if (onAssign != null) IconButton(
            icon: Icon(Icons.create_new_folder_outlined, size: 18, color: scheme.onSurfaceVariant),
            onPressed: onAssign,
            visualDensity: VisualDensity.compact,
          ),
        ])));
  }
}

/// Bottom sheet to save/unsave a track into folders. Shared between the
/// search page and the music card, so any "save to folder" button opens
/// the same picker.
Future<void> showFolderAssignSheet(
  BuildContext context, {
  required String name,
  required String artist,
  required String image,
}) async {
  await FavoritesFoldersService.ensureLoaded();
  final key = FavoritesFoldersService.itemKey(name, artist);
  final meta = FolderItem(key: key, name: name, artist: artist, image: image,
      addedAt: DateTime.now().millisecondsSinceEpoch);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => ValueListenableBuilder<List<FavFolder>>(
      valueListenable: FavoritesFoldersService.foldersNotifier,
      builder: (ctx, folders, _) => ValueListenableBuilder<Map<String, List<String>>>(
        valueListenable: FavoritesFoldersService.assignNotifier,
        builder: (ctx, _, _) {
          final scheme = Theme.of(ctx).colorScheme;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(children: [
                    Expanded(child: Text(L.favFolderAssignTitle,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                  ]),
                ),
                const SizedBox(height: 8),
                if (folders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(L.searchFoldersHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  ),
                ...folders.map((f) {
                  final checked = FavoritesFoldersService.foldersForItem(key).contains(f.id);
                  return CheckboxListTile(
                    value: checked,
                    controlAffinity: ListTileControlAffinity.leading,
                    secondary: CircleAvatar(
                      backgroundColor: f.color.withValues(alpha: 0.25),
                      child: Text(f.emoji, style: const TextStyle(fontSize: 16)),
                    ),
                    title: Text(f.name),
                    onChanged: (_) =>
                        FavoritesFoldersService.toggleItemInFolder(key, f.id, meta: meta),
                  );
                }),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.add_rounded),
                  title: Text(L.favFolderNew),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await showFolderEditorSheet(context);
                  },
                ),
              ]),
            ),
          );
        },
      ),
    ),
  );
}

/// Create-or-edit sheet for a folder (name, emoji, color). Shared between
/// the search page's folder tab and the quick "new folder" shortcut above.
Future<void> showFolderEditorSheet(BuildContext context, {FavFolder? existing}) async {
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final descCtrl = TextEditingController(text: existing?.description ?? '');
  String emoji   = existing?.emoji ?? kFavFolderEmojis.first;
  int colorValue = existing?.colorValue ?? kFavFolderColors.first;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
      final scheme = Theme.of(ctx).colorScheme;
      return Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(existing == null ? L.favFolderNew : L.favFolderEdit,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(children: [
            Container(
              width: 52, height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(colorValue).withValues(alpha: 0.25),
                borderRadius: AppRadius.mdR,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: nameCtrl,
                autofocus: existing == null,
                decoration: InputDecoration(
                  hintText: L.favFolderNamePlaceholder,
                  border: OutlineInputBorder(borderRadius: AppRadius.smR),
                  isDense: true,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: descCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: L.favFolderDescPlaceholder,
              border: OutlineInputBorder(borderRadius: AppRadius.smR),
              isDense: true,
            ),
          ),
          const SizedBox(height: 18),
          Text(L.favFolderEmoji, style: Theme.of(ctx).textTheme.labelMedium
              ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: kFavFolderEmojis.map((e) {
            final selected = e == emoji;
            return GestureDetector(
              onTap: () => setSheet(() => emoji = e),
              child: Container(
                width: 40, height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                  border: selected ? Border.all(color: scheme.primary, width: 2) : null,
                ),
                child: Text(e, style: const TextStyle(fontSize: 18)),
              ),
            );
          }).toList()),
          const SizedBox(height: 18),
          Text(L.favFolderColor, style: Theme.of(ctx).textTheme.labelMedium
              ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: kFavFolderColors.map((c) {
            final selected = c == colorValue;
            return GestureDetector(
              onTap: () => setSheet(() => colorValue = c),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(c),
                  border: selected
                      ? Border.all(color: scheme.onSurface, width: 2.5)
                      : null,
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 22),
          Row(children: [
            if (existing != null) ...[
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(L.favFolderDelete),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: ctx,
                      builder: (dctx) => AlertDialog(
                        content: Text(L.favFolderDeleteConfirm),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dctx, false), child: Text(L.commonCancel)),
                          FilledButton.tonal(
                            style: FilledButton.styleFrom(foregroundColor: scheme.error),
                            onPressed: () => Navigator.pop(dctx, true),
                            child: Text(L.favFolderDelete),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await FavoritesFoldersService.deleteFolder(existing.id);
                      if (ctx.mounted) Navigator.pop(ctx, false);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(existing == null ? L.favFolderCreate : L.favFolderSave),
              ),
            ),
          ]),
        ]),
        ),
      );
    }),
  );

  if (result != true) return;
  final name = nameCtrl.text.trim();
  final desc = descCtrl.text.trim();
  if (existing == null) {
    if (name.isEmpty) return;
    await FavoritesFoldersService.createFolder(name, emoji, colorValue, description: desc);
  } else {
    await FavoritesFoldersService.updateFolder(existing.id,
        name: name.isEmpty ? existing.name : name, emoji: emoji, colorValue: colorValue,
        description: desc);
  }
}

/// Wraps _ItemTile and keeps its folder badges/button in sync with
/// FavoritesFoldersService, so track cards update live when the user
/// saves or unsaves them from a folder. Tracks only — no albums/artists.
class _FolderAwareItemTile extends StatelessWidget {
  final String name, sub, imageUrl, rank, artist, image;
  final Future<String>? imageFuture;
  const _FolderAwareItemTile({
    required this.name, required this.sub, required this.imageUrl, required this.rank,
    required this.artist, required this.image, this.imageFuture,
  });

  @override
  Widget build(BuildContext context) {
    final key = FavoritesFoldersService.itemKey(name, artist);
    return ValueListenableBuilder<Map<String, List<String>>>(
      valueListenable: FavoritesFoldersService.assignNotifier,
      builder: (ctx, _, _) {
        final ids = FavoritesFoldersService.foldersForItem(key);
        final emojis = FavoritesFoldersService.foldersNotifier.value
            .where((f) => ids.contains(f.id)).map((f) => f.emoji).toList();
        return _ItemTile(
          name: name, sub: sub, imageUrl: imageUrl, rank: rank, imageFuture: imageFuture,
          folderEmojis: emojis,
          onAssign: () => showFolderAssignSheet(context, name: name, artist: artist, image: image),
        );
      },
    );
  }
}

/// The Folders tab body: a horizontal chip row to pick/create/edit a
/// folder, and below it the list of items saved in the selected folder.
/// Real, separate page for browsing folders: a grid of folder cards, and a
/// button at the bottom to create a new one. Tapping a card opens
/// _FolderDetailPage with that folder's saved tracks and sort options.
class FoldersGridPage extends StatelessWidget {
  final LastFmService service;
  const FoldersGridPage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    FavoritesFoldersService.ensureLoaded();
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 16, 2),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(child: Text(L.searchFolders,
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
          ]),
        ),
        Expanded(
          child: ValueListenableBuilder<List<FavFolder>>(
            valueListenable: FavoritesFoldersService.foldersNotifier,
            builder: (ctx, folders, _) {
              if (folders.isEmpty) {
                return Center(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(L.searchFoldersHint, textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                ));
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                itemCount: folders.length,
                itemBuilder: (ctx, i) => _FolderCard(
                  folder: folders[i],
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => _FolderDetailPage(service: service, folder: folders[i]))),
                  onLongPress: () => showFolderEditorSheet(context, existing: folders[i]),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: Text(L.favFolderNew),
                onPressed: () => showFolderEditorSheet(context),
              ),
            ),
          ),
        ),
      ])),
    );
  }
}

/// A single square folder card: emoji, name, description, item count.
class _FolderCard extends StatelessWidget {
  final FavFolder    folder;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _FolderCard({required this.folder, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<Map<String, List<String>>>(
      valueListenable: FavoritesFoldersService.assignNotifier,
      builder: (ctx, _, _) {
        final count = FavoritesFoldersService.itemsInFolder(folder.id).length;
        return InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: AppRadius.lgR,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: folder.color.withValues(alpha: 0.16),
              borderRadius: AppRadius.lgR,
              border: Border.all(color: folder.color.withValues(alpha: 0.4)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(folder.emoji, style: const TextStyle(fontSize: 30)),
              const Spacer(),
              Text(folder.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              if (folder.description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(folder.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 6),
              Text('$count', style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
            ]),
          ),
        );
      },
    );
  }
}

enum _FolderSort { recent, oldest, artistAz, titleAz }

/// Detail page for one folder: its saved tracks, sortable, removable.
class _FolderDetailPage extends StatefulWidget {
  final LastFmService service;
  final FavFolder     folder;
  const _FolderDetailPage({required this.service, required this.folder});

  @override
  State<_FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends State<_FolderDetailPage> {
  _FolderSort _sort = _FolderSort.recent;

  void _openItem(FolderItem item) {
    final data = <String, dynamic>{
      'name': item.name,
      'artist': {'name': item.artist},
      'image': item.image.isEmpty ? [] : [{'#text': item.image, 'size': 'large'}],
    };
    showDetailSheet(context, data, 'tracks', widget.service);
  }

  List<FolderItem> _sorted(List<FolderItem> items) {
    final list = List<FolderItem>.from(items);
    switch (_sort) {
      case _FolderSort.recent:   list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      case _FolderSort.oldest:   list.sort((a, b) => a.addedAt.compareTo(b.addedAt));
      case _FolderSort.artistAz: list.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
      case _FolderSort.titleAz:  list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 16, 2),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Text(widget.folder.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.folder.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              if (widget.folder.description.isNotEmpty)
                Text(widget.folder.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ])),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showFolderEditorSheet(context, existing: widget.folder),
            ),
          ]),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _sortChip(L.favSortRecent,   _FolderSort.recent),
              _sortChip(L.favSortOldest,   _FolderSort.oldest),
              _sortChip(L.favSortArtistAz, _FolderSort.artistAz),
              _sortChip(L.favSortTitleAz,  _FolderSort.titleAz),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ValueListenableBuilder<Map<String, List<String>>>(
            valueListenable: FavoritesFoldersService.assignNotifier,
            builder: (ctx, _, _) {
              final items = _sorted(FavoritesFoldersService.itemsInFolder(widget.folder.id));
              if (items.isEmpty) {
                return Center(child: Text(L.favFolderEmpty,
                    style: TextStyle(color: scheme.onSurfaceVariant)));
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final it = items[i];
                  return ListTile(
                    onTap: () => _openItem(it),
                    leading: ClipRRect(
                      borderRadius: AppRadius.smR,
                      child: SizedBox(width: 44, height: 44,
                        child: it.image.isNotEmpty
                            ? Image.network(it.image, fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(color: scheme.secondaryContainer))
                            : Container(color: scheme.secondaryContainer,
                                child: Icon(Icons.music_note_rounded, color: scheme.onSecondaryContainer, size: 20)),
                      ),
                    ),
                    title: Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: it.artist.isEmpty ? null
                        : Text(it.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: Icon(Icons.close_rounded, size: 20, color: scheme.onSurfaceVariant),
                      onPressed: () => FavoritesFoldersService.toggleItemInFolder(
                          it.key, widget.folder.id, meta: it),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ])),
    );
  }

  Widget _sortChip(String label, _FolderSort mode) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _sort == mode,
      showCheckmark: false,
      onSelected: (_) => setState(() => _sort = mode),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    return Center(child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded, size: 48, color: scheme.error),
        const SizedBox(height: 16),
        Text(message,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        FilledButton.tonal(onPressed: onRetry,
            child: Text(L.commonRetry)),
      ])));
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _extractImage(dynamic images, {bool large = false}) {
  if (images == null) return '';
  final list = images is List ? images : [];
  if (list.isEmpty) return '';
  try {
    final entry = list.lastWhere(
        (i) => i is Map && i['size'] == 'extralarge', orElse: () => list.last);
    var url = (entry is Map ? entry['#text'] ?? '' : '').toString();
    if (url.isEmpty) return '';
    // Upsample Last.fm CDN: replace the size segment in the path.
    // /300x300/ → /500x500/  (CDN supports at least up to 500)
    if (large && url.contains('lastfm.freetls.fastly.net')) {
      url = url.replaceFirstMapped(
        RegExp(r'/\d+x\d+/'), (_) => '/500x500/');
    }
    return url;
  } catch (_) { return ''; }
}

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}k';
  return n.toString();
}


String _fmtDate(String raw) {
  if (raw.isEmpty) return '';
  try {
    final parts = raw.split(', ');
    return parts.length == 2 ? '${parts[0]} · ${parts[1]}' : raw;
  } catch (_) { return raw; }
}

/// Converts a track's Unix timestamp (date['uts']) to the device's local time
/// and returns "DD Mmm · HH:MM". Falls back to _fmtDate if uts is absent.
String _fmtTrackDateLocal(Map t) {
  final uts = t['date']?['uts']?.toString() ?? '';
  if (uts.isNotEmpty) {
    final sec = int.tryParse(uts);
    if (sec != null) {
      final dt  = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
      final mon = L.months[dt.month]; // localised month abbreviations
      final h   = dt.hour.toString().padLeft(2, '0');
      final m   = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} $mon · $h:$m';
    }
  }
  return _fmtDate((t['date']?['#text'] ?? '').toString());
}