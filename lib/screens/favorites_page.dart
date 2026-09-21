// lib/screens/favorites_page.dart
// ══════════════════════════════════════════════════════════════════════════
//  FavoritesPage — full list of loved tracks: search, sort filters, artwork,
//  inline removal (tap the heart to unlove). Folders live in the Search tab
//  now (see favorites_folders_service.dart), not here.
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../theme/m3_motion.dart';
import '../widgets/m3_components.dart';
import '../widgets/skeleton.dart';
import '../app_state.dart';
import '../l10n/l10n.dart';
import '../services/data_cache.dart';
import '../services/lastfm_service.dart';
import '../services/favorites_folders_service.dart' show FavoritesFoldersService;
import 'home_screen.dart' show showDetailSheet, showFolderAssignSheet;
import 'track_row_tile.dart';

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

  @override
  void initState() {
    super.initState();
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
    // Also drop it from any folder it was saved in.
    FavoritesFoldersService.clearItem(
        FavoritesFoldersService.itemKey(name, artist));

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

  @override
  Widget build(BuildContext context) {
    final items  = _filtered;

    return Scaffold(
      body: SafeArea(child: Column(children: [
        M3PageHeader(title: L.favPageTitle),
        Expanded(child: M3Switcher(
        duration: const Duration(milliseconds: 250),
        child: _loading
          ? const SkeletonList(key: ValueKey('load'))
          : Column(key: const ValueKey('content'), children: [
              M3SearchField(
                hint: L.favSearchHint,
                onChanged: (v) => setState(() => _query = v),
              ),
              M3ButtonGroup<_SortMode>(
                items: [
                  (_SortMode.recent,   L.favSortRecent),
                  (_SortMode.oldest,   L.favSortOldest),
                  (_SortMode.artistAz, L.favSortArtistAz),
                  (_SortMode.titleAz,  L.favSortTitleAz),
                ],
                selected: _sort,
                onSelected: (m) => setState(() => _sort = m),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: items.isEmpty
                    ? M3EmptyState(
                        icon: Icons.favorite_border_rounded,
                        message: L.favEmpty)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final t = items[i] as Map<String, dynamic>;
                          // Light fade-in, no popup feel
                          return TweenAnimationBuilder<double>(
                            key: ValueKey(t['name']?.toString() ?? i),
                            tween: Tween(begin: 0, end: 1),
                            duration: M3Motion.effectsDefaultDuration,
                            curve: M3Motion.effectsDefault,
                            builder: (_, v, child) => Opacity(opacity: v, child: child),
                            child: M3SegmentTile(
                              index: i,
                              count: items.length,
                              child: _FavoriteListTile(
                                track:  t,
                                onTap:  () => showDetailSheet(ctx, Map<String, dynamic>.from(t), 'tracks', widget.service),
                                onRemove: () => _remove(t),
                              ),
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
}

class _FavoriteListTile extends StatelessWidget {
  final Map<String, dynamic> track;
  final VoidCallback         onTap;
  final VoidCallback         onRemove;

  const _FavoriteListTile({
    required this.track,
    required this.onTap,
    required this.onRemove,
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
    final name   = (track['name'] ?? '').toString();
    final artist = (track['artist']?['name'] ?? '').toString();
    final rawUrl = _extractImage(track['image']);

    // Long-pressing the heart opens the folder picker, same as everywhere
    // else a track can be saved into a folder.
    return TrackRowTile(
      name: name,
      artist: artist,
      imageUrl: rawUrl,
      onTap: onTap,
      trailing: GestureDetector(
        onLongPress: () => showFolderAssignSheet(context, name: name, artist: artist, image: rawUrl),
        child: IconButton.filledTonal(
          icon: Icon(Icons.favorite_rounded,
              color: Theme.of(context).colorScheme.primary, size: 20),
          onPressed: onRemove,
        ),
      ),
    );
  }
}
