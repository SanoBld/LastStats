// lib/screens/favorites_page.dart
// ══════════════════════════════════════════════════════════════════════════
//  FavoritesPage — full list of loved tracks: search, sort filters, artwork,
//  inline removal (tap the heart to unlove), and folders (create a folder
//  with an emoji + a color, sort loved tracks into it, filter by it). The
//  folders themselves are saved with the ls_ prefix so they ride along with
//  the normal Settings > Backup export/import automatically.
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../app_state.dart';
import '../l10n/l10n.dart';
import '../services/data_cache.dart';
import '../services/image_service.dart';
import '../services/lastfm_service.dart';
import '../services/favorites_folders_service.dart';
import 'home_screen.dart' show showDetailSheet;
import '../theme/story_style.dart';

enum _SortMode { recent, oldest, artistAz, titleAz }

class FavoritesPage extends StatefulWidget {
  final LastFmService service;
  const FavoritesPage({super.key, required this.service});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<dynamic>  _tracks  = [];
  bool           _loading = true;
  String         _query   = '';
  _SortMode      _sort    = _SortMode.recent;
  String?        _folderFilter; // null = "All"

  @override
  void initState() {
    super.initState();
    FavoritesFoldersService.ensureLoaded();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await widget.service.getLovedTracks(limit: 300);
      if (mounted) setState(() { _tracks = t; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(Map<String, dynamic> track) async {
    final name   = (track['name'] ?? '').toString();
    final artist = (track['artist']?['name'] ?? '').toString();

    setState(() => _tracks.remove(track));
    final newSet = Set<String>.from(lovedTrackKeysNotifier.value)
      ..remove(lovedKey(artist, name));
    lovedTrackKeysNotifier.value = newSet;
    FavoritesFoldersService.clearTrack(lovedKey(artist, name));

    final svc = LastFmService(
      apiKey:     widget.service.apiKey,
      username:   widget.service.username,
      secret:     secretKeyNotifier.value,
      sessionKey: sessionKeyNotifier.value,
    );
    try {
      await svc.unloveTrack(name, artist);
      await DataCache.invalidate(DataCache.keyLovedTracks());
    } catch (_) {
      // Re-add on failure
      if (mounted) setState(() => _tracks.add(track));
      lovedTrackKeysNotifier.value = {...lovedTrackKeysNotifier.value, lovedKey(artist, name)};
    }
  }

  String _keyOf(dynamic t) => lovedKey(
      (t['artist']?['name'] ?? '').toString(), (t['name'] ?? '').toString());

  List<dynamic> get _filtered {
    var list = _tracks;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((t) {
        final name   = (t['name'] ?? '').toString().toLowerCase();
        final artist = (t['artist']?['name'] ?? '').toString().toLowerCase();
        return name.contains(q) || artist.contains(q);
      }).toList();
    }
    if (_folderFilter != null) {
      list = list.where((t) => FavoritesFoldersService
          .foldersForTrack(_keyOf(t)).contains(_folderFilter)).toList();
    }

    final sorted = List<dynamic>.from(list);
    switch (_sort) {
      case _SortMode.recent:
        sorted.sort((a, b) => _uts(b).compareTo(_uts(a)));
      case _SortMode.oldest:
        sorted.sort((a, b) => _uts(a).compareTo(_uts(b)));
      case _SortMode.artistAz:
        sorted.sort((a, b) => (a['artist']?['name'] ?? '').toString()
            .toLowerCase().compareTo((b['artist']?['name'] ?? '').toString().toLowerCase()));
      case _SortMode.titleAz:
        sorted.sort((a, b) => (a['name'] ?? '').toString()
            .toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase()));
    }
    return sorted;
  }

  int _uts(dynamic t) => int.tryParse(t['date']?['uts']?.toString() ?? '0') ?? 0;

  // ── Folder creation / editing ────────────────────────────────────────────

  Future<void> _showFolderEditor({FavFolder? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
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
                        if (mounted) {
                          setState(() { if (_folderFilter == existing.id) _folderFilter = null; });
                        }
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
        );
      }),
    );

    if (result != true) return;
    final name = nameCtrl.text.trim();
    if (existing == null) {
      if (name.isEmpty) return;
      await FavoritesFoldersService.createFolder(name, emoji, colorValue);
    } else {
      await FavoritesFoldersService.updateFolder(existing.id,
          name: name.isEmpty ? existing.name : name, emoji: emoji, colorValue: colorValue);
    }
    if (mounted) setState(() {});
  }

  Future<void> _showAssignSheet(dynamic track) async {
    await FavoritesFoldersService.ensureLoaded();
    final trackKey = _keyOf(track);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ValueListenableBuilder<List<FavFolder>>(
        valueListenable: FavoritesFoldersService.foldersNotifier,
        builder: (ctx, folders, _) {
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
                    child: Text(L.favFolderEmpty, style: TextStyle(color: scheme.onSurfaceVariant)),
                  ),
                ...folders.map((f) {
                  final checked = FavoritesFoldersService.foldersForTrack(trackKey).contains(f.id);
                  return CheckboxListTile(
                    value: checked,
                    controlAffinity: ListTileControlAffinity.leading,
                    secondary: CircleAvatar(
                      backgroundColor: f.color.withValues(alpha: 0.25),
                      child: Text(f.emoji, style: const TextStyle(fontSize: 16)),
                    ),
                    title: Text(f.name),
                    onChanged: (_) async {
                      await FavoritesFoldersService.toggleTrackInFolder(trackKey, f.id);
                      if (mounted) setState(() {});
                    },
                  );
                }),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.add_rounded),
                  title: Text(L.favFolderNew),
                  onTap: () { Navigator.pop(ctx); _showFolderEditor(); },
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items  = _filtered;

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
            Expanded(child:
              Text(L.favPageTitle, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        Expanded(child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _loading
          ? const Center(key: ValueKey('load'), child: CircularProgressIndicator())
          : Column(key: const ValueKey('content'), children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText:   L.favSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(borderRadius: AppRadius.mdR),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),

              // ── Folder shelf ─────────────────────────────────────────────
              ValueListenableBuilder<List<FavFolder>>(
                valueListenable: FavoritesFoldersService.foldersNotifier,
                builder: (ctx, folders, _) => SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _folderChip(L.favFoldersAll, null, null, null),
                      for (final f in folders)
                        _folderChip(f.name, f.id, f.emoji, f.color),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: const Icon(Icons.add_rounded, size: 16),
                          label: Text(L.favFolderNew),
                          onPressed: () => _showFolderEditor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),

              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _sortChip(L.favSortRecent,   _SortMode.recent),
                    _sortChip(L.favSortOldest,   _SortMode.oldest),
                    _sortChip(L.favSortArtistAz, _SortMode.artistAz),
                    _sortChip(L.favSortTitleAz,  _SortMode.titleAz),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text(
                        _folderFilter != null ? L.favFolderEmpty : L.favEmpty,
                        style: TextStyle(color: scheme.onSurfaceVariant)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final t = items[i] as Map<String, dynamic>;
                          // Light fade-in, no popup feel
                          return TweenAnimationBuilder<double>(
                            key: ValueKey(t['name']?.toString() ?? i),
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 220),
                            builder: (_, v, child) => Opacity(opacity: v, child: child),
                            child: _FavoriteListTile(
                              track:  t,
                              onTap:  () => showDetailSheet(ctx, Map<String, dynamic>.from(t), 'tracks', widget.service),
                              onRemove: () => _remove(t),
                              onAssign: () => _showAssignSheet(t),
                            ),
                          );
                        },
                      ),
              ),
            ]),
      )),
      ])),
    );
  }

  Widget _folderChip(String label, String? id, String? emoji, Color? color) {
    final selected = _folderFilter == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onLongPress: id == null ? null : () {
          final list = FavoritesFoldersService.foldersNotifier.value;
          FavFolder? f;
          for (final x in list) { if (x.id == id) { f = x; break; } }
          if (f != null) _showFolderEditor(existing: f);
        },
        child: ChoiceChip(
          avatar: emoji != null ? Text(emoji, style: const TextStyle(fontSize: 14)) : null,
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          selectedColor: color?.withValues(alpha: 0.32),
          onSelected: (_) => setState(() => _folderFilter = selected ? null : id),
        ),
      ),
    );
  }

  Widget _sortChip(String label, _SortMode mode) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _sort == mode,
      showCheckmark: false,
      onSelected: (_) => setState(() => _sort = mode),
    ),
  );
}

class _FavoriteListTile extends StatelessWidget {
  final Map<String, dynamic> track;
  final VoidCallback         onTap;
  final VoidCallback         onRemove;
  final VoidCallback         onAssign;

  const _FavoriteListTile({
    required this.track,
    required this.onTap,
    required this.onRemove,
    required this.onAssign,
  });

  String _extractImage(dynamic raw) {
    if (raw is! List) return '';
    for (final img in raw.reversed) {
      final url = (img is Map ? img['#text'] : '')?.toString() ?? '';
      if (url.isNotEmpty) return url;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final name   = (track['name'] ?? '').toString();
    final artist = (track['artist']?['name'] ?? '').toString();
    final rawUrl = _extractImage(track['image']);
    final trackKey = lovedKey(artist, name);

    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: AppRadius.smR,
        child: SizedBox(
          width: 44, height: 44,
          child: FutureBuilder<String>(
            future: ImageService.resolveTrack(name, artist,
                lastfmUrl: rawUrl.isNotEmpty ? rawUrl : null),
            builder: (ctx, snap) {
              final url = snap.data ?? rawUrl;
              if (url.isEmpty) {
                return Container(
                  color: scheme.secondaryContainer,
                  child: Icon(Icons.music_note_rounded,
                      color: scheme.onSecondaryContainer, size: 20),
                );
              }
              return Image.network(url, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: scheme.secondaryContainer,
                    child: Icon(Icons.music_note_rounded,
                        color: scheme.onSecondaryContainer, size: 20),
                  ));
            },
          ),
        ),
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(children: [
        Expanded(child: Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
        // Small emoji strip for the folders this track belongs to, if any.
        ValueListenableBuilder<Map<String, List<String>>>(
          valueListenable: FavoritesFoldersService.assignNotifier,
          builder: (ctx, _, _) {
            final ids = FavoritesFoldersService.foldersForTrack(trackKey);
            if (ids.isEmpty) return const SizedBox.shrink();
            final folders = FavoritesFoldersService.foldersNotifier.value
                .where((f) => ids.contains(f.id)).take(3);
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(folders.map((f) => f.emoji).join(''),
                  style: const TextStyle(fontSize: 12)),
            );
          },
        ),
      ]),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          icon: Icon(Icons.create_new_folder_outlined, size: 20, color: scheme.onSurfaceVariant),
          onPressed: onAssign,
        ),
        IconButton(
          icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
          onPressed: onRemove,
        ),
      ]),
    );
  }
}
