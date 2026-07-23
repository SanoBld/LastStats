// lib/screens/favorites_page.dart
// ══════════════════════════════════════════════════════════════════════════
//  FavoritesPage — full list of loved tracks: search, sort filters, artwork,
//  and inline removal (tap the heart to unlove).
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../app_state.dart';
import '../l10n/l10n.dart';
import '../services/data_cache.dart';
import '../services/image_service.dart';
import '../services/lastfm_service.dart';
import 'home_screen.dart' show showDetailSheet;

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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
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
                    ? Center(child: Text(L.favEmpty,
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
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final name   = (track['name'] ?? '').toString();
    final artist = (track['artist']?['name'] ?? '').toString();
    final rawUrl = _extractImage(track['image']);

    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
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
      subtitle: Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      trailing: IconButton(
        icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
        onPressed: onRemove,
      ),
    );
  }
}