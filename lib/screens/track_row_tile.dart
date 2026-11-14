// lib/screens/track_row_tile.dart
// ══════════════════════════════════════════════════════════════════════════
//  One consistent look for "a track in a list": resolved artwork, name,
//  artist, and a trailing slot for whatever action the screen needs (heart,
//  add, remove, drag handle...). Used by Favorites, folder pages, and the
//  add-to-folder search so every track list in the app looks the same.
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../services/image_service.dart';
import '../theme/story_style.dart';
import '../widgets/m3_popup_menu.dart';
import '../widgets/m3_marquee.dart';

class TrackRowTile extends StatelessWidget {
  final String name;
  final String artist;
  final String imageUrl; // raw Last.fm url, used as a fallback while resolving
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelect; // adds "Select" to the bubble
  final Widget? trailing;

  const TrackRowTile({
    super.key,
    required this.name,
    required this.artist,
    required this.imageUrl,
    this.onTap,
    this.onLongPress,
    this.onSelect,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Long press / right click opens the bubble; old long-press action
    // ("add to folder") is its first entry.
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onSecondaryTapUp: (d) => showTrackMenu(context,
          name: name, artist: artist, at: d.globalPosition, onAddToFolder: onLongPress, onSelect: onSelect),
      child: ListTile(
      onTap: onTap,
      onLongPress: () => showTrackMenu(context,
          name: name, artist: artist, onAddToFolder: onLongPress, onSelect: onSelect),
      leading: ClipRRect(
        borderRadius: AppRadius.smR,
        child: SizedBox(
          width: 48, height: 48,
          child: FutureBuilder<String>(
            future: ImageService.resolveTrack(name, artist,
                lastfmUrl: imageUrl.isNotEmpty ? imageUrl : null),
            builder: (ctx, snap) {
              final url = snap.data ?? imageUrl;
              if (url.isEmpty) {
                return Container(
                  color: scheme.secondaryContainer,
                  child: Icon(Icons.music_note_rounded,
                      color: scheme.onSecondaryContainer, size: 20),
                );
              }
              return Image.network(url, fit: BoxFit.cover, cacheWidth: 160, cacheHeight: 160,
                  errorBuilder: (_, _, _) => Container(
                    color: scheme.secondaryContainer,
                    child: Icon(Icons.music_note_rounded,
                        color: scheme.onSecondaryContainer, size: 20),
                  ));
            },
          ),
        ),
      ),
      title: M3Marquee(name),
      subtitle: artist.isEmpty ? null : Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      trailing: trailing,
    ));
  }
}
