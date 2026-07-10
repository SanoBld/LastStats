// lib/screens/favorites_page.dart
// ══════════════════════════════════════════════════════════════════════════
//  FavoritesPage — full list of loved (favorite) tracks, with search filter.
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/lastfm_service.dart';
import 'home_screen.dart' show showDetailSheet;

class FavoritesPage extends StatefulWidget {
  final LastFmService service;
  const FavoritesPage({super.key, required this.service});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<dynamic> _tracks  = [];
  bool          _loading = true;
  String        _query   = '';

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

  List<dynamic> get _filtered {
    if (_query.isEmpty) return _tracks;
    final q = _query.toLowerCase();
    return _tracks.where((t) {
      final name   = (t['name'] ?? '').toString().toLowerCase();
      final artist = (t['artist']?['name'] ?? '').toString().toLowerCase();
      return name.contains(q) || artist.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items  = _filtered;

    return Scaffold(
      appBar: AppBar(title: Text(L.favPageTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
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
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text(L.favEmpty,
                        style: TextStyle(color: scheme.onSurfaceVariant)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final t      = items[i] as Map<String, dynamic>;
                          final name   = (t['name'] ?? '').toString();
                          final artist = (t['artist']?['name'] ?? '').toString();
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: scheme.secondaryContainer,
                              child: Icon(Icons.music_note_rounded,
                                  color: scheme.onSecondaryContainer),
                            ),
                            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.favorite_rounded,
                                color: Colors.redAccent, size: 18),
                            onTap: () => showDetailSheet(
                                ctx, Map<String, dynamic>.from(t), 'tracks', widget.service),
                          );
                        },
                      ),
              ),
            ]),
    );
  }
}
