// lib/screens/track_row_tile.dart
// ══════════════════════════════════════════════════════════════════════════
//  One consistent look for "a track in a list": resolved artwork, name,
//  artist, and a trailing slot for whatever action the screen needs (heart,
//  add, remove, drag handle...). Used by Favorites, folder pages, and the
//  add-to-folder search so every track list in the app looks the same.
// ══════════════════════════════════════════════════════════════════════════

import '../services/offline_image_cache.dart';
import 'package:flutter/material.dart';
import '../services/image_service.dart';
import '../theme/story_style.dart';

class TrackRowTile extends StatelessWidget {
  final String name;
  final String artist;
  final String imageUrl; // raw Last.fm url, used as a fallback while resolving
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  const TrackRowTile({
    super.key,
    required this.name,
    required this.artist,
    required this.imageUrl,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: ClipRRect(
        borderRadius: AppRadius.smR,
        child: SizedBox(
          width: 48, height: 48,
          child: FutureBuilder<String>(
            future: ImageService.resolveTrack(name, artist,
                lastfmUrl: imageUrl.isNotEmpty ? imageUrl : null),
            builder: (ctx, snap) {
              final url = snap.data ?? imageUrl;
              Widget fallback() => Container(
                    color: scheme.secondaryContainer,
                    child: Icon(Icons.music_note_rounded,
                        color: scheme.onSecondaryContainer, size: 20),
                  );
              if (url.isEmpty) return fallback();
              // Resized url first; if that variant fails, the original url.
              final shown = OfflineImageCache.sized(
                  url, 48, MediaQuery.of(ctx).devicePixelRatio);
              return Image.network(shown, fit: BoxFit.cover, cacheWidth: 160, cacheHeight: 160,
                  errorBuilder: (_, _, _) {
                    if (shown == url) return fallback();
                    OfflineImageCache.markSizedBad(shown);
                    return Image.network(url, fit: BoxFit.cover, cacheWidth: 160, cacheHeight: 160,
                        errorBuilder: (_, _, _) => fallback());
                  });
            },
          ),
        ),
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: artist.isEmpty ? null : Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      trailing: trailing,
    );
  }
}
