// lib/screens/settings/about_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/l10n.dart';
import '../../app_state.dart';
import '../../services/update_service.dart';
import 'settings_helpers.dart';

/// Picks the self-contained logo SVG (own background baked in): the plain
/// mono logo by default, the red-dot "Nothing" variant only when that theme
/// is active — matching brightness either way.
String _logoAsset(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final family = themeStyleNotifier.value == 'nothing' ? 'app_logo_nothing' : 'app_logo';
  return 'assets/icons/${family}_${dark ? 'black_bg' : 'white_bg'}.svg';
}

/// Full 10-language lookup — falls back to English, then French.
String _tr(Map<String, String> byLocale) =>
    byLocale[localeNotifier.value] ?? byLocale['en'] ?? byLocale['fr'] ?? '';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(L.settingsAbout),
        centerTitle: false,
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        // ── Logo / header ─────────────────────────────────────────────────
        Center(child: Column(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SvgPicture.asset(_logoAsset(context), width: 80, height: 80),
          ),
          const SizedBox(height: 14),
          Text('LastStats',
              style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(UpdateService.displayVersion ?? 'dev',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(L.aboutTagline,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 24),
        ])),

        // ── Project description ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, size: 18, color: scheme.secondary),
              const SizedBox(width: 10),
              Expanded(child: Text(L.settingsAboutProjectDesc,
                  style: text.bodySmall?.copyWith(color: scheme.onSecondaryContainer))),
            ]),
          ),
        ),

        // ── App info ──────────────────────────────────────────────────────
        SettingsSection(label: L.aboutAppInfo, children: [
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(L.settingsVersion,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            trailing: Text(UpdateService.displayVersion ?? 'dev',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.web_rounded),
            title: Text(L.settingsWebVersion,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(L.settingsWebVersionSub,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            trailing: const Icon(Icons.open_in_new_rounded, size: 16),
            onTap: () => _open('https://sanobld.github.io/LastStats-Web/'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.code_rounded),
            title: Text(L.settingsSourceCode,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(L.settingsSourceCodeSub,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            trailing: const Icon(Icons.open_in_new_rounded, size: 16),
            onTap: () => _open('https://github.com/SanoBld/LastStats'),
          ),
        ]),

        const SizedBox(height: 16),

        // ── Coup de cœur / credits ──────────────────────────────────────────
        SettingsSection(
          label: _tr({
            'fr': 'Coups de cœur', 'en': 'Favorites',
            'es': 'Favoritos', 'de': 'Favoriten', 'it': 'Preferiti',
            'pt': 'Favoritos', 'ru': 'Избранное', 'ja': 'お気に入り',
            'zh': '精选推荐', 'ar': 'المفضلة',
          }),
          children: [
            ListTile(
              leading: const Icon(Icons.library_music_rounded),
              title: const Text('Metrolist',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_tr({
                'fr': 'Client YouTube Music avancé.',
                'en': 'Advanced YouTube Music client.',
                'es': 'Cliente avanzado de YouTube Music.',
                'de': 'Fortschrittlicher YouTube-Music-Client.',
                'it': 'Client avanzato per YouTube Music.',
                'pt': 'Cliente avançado do YouTube Music.',
                'ru': 'Продвинутый клиент YouTube Music.',
                'ja': '高機能な YouTube Music クライアント。',
                'zh': '功能强大的 YouTube Music 客户端。',
                'ar': 'عميل متقدم لتطبيق يوتيوب ميوزك.',
              }), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              trailing: const Icon(Icons.open_in_new_rounded, size: 16),
              onTap: () => _open('https://github.com/MetrolistGroup/Metrolist'),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.flare_rounded),
              title: const Text('Better Nothing Music Visualizer',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_tr({
                'fr': 'Synchronise les Glyphs des téléphones Nothing à la musique.',
                'en': 'Syncs the Glyphs of Nothing phones to the music.',
                'es': 'Sincroniza los Glyphs de los Nothing phones con la música.',
                'de': 'Synchronisiert die Glyphs der Nothing-Phones mit der Musik.',
                'it': 'Sincronizza i Glyph dei telefoni Nothing con la musica.',
                'pt': 'Sincroniza os Glyphs dos telefones Nothing com a música.',
                'ru': 'Синхронизирует Glyph телефонов Nothing с музыкой.',
                'ja': 'Nothing フォンの Glyph を音楽に同期させます。',
                'zh': '将 Nothing 手机的 Glyph 灯效与音乐同步。',
                'ar': 'يزامن مصابيح Glyph في هواتف Nothing مع الموسيقى.',
              }), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              trailing: const Icon(Icons.open_in_new_rounded, size: 16),
              onTap: () => _open('https://github.com/Aleks-Levet/better-nothing-music-visualizer'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Support ───────────────────────────────────────────────────────
        SettingsSection(label: L.settingsAboutSupport, children: [
          ListTile(
            leading: const Icon(Icons.star_rounded),
            title: Text(L.settingsAboutSupport,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(L.settingsAboutSupportSub,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            trailing: const Icon(Icons.open_in_new_rounded, size: 16),
            onTap: () => _open('https://github.com/SanoBld/LastStats'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: _SafeSvgIcon(asset: 'assets/icons/discord.svg',
                fallback: Icons.forum_rounded, color: scheme.primary),
            title: Text(L.aboutDiscord,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(L.aboutDiscordSub,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            trailing: const Icon(Icons.open_in_new_rounded, size: 16),
            onTap: () => _open('https://discord.gg/JjqmkQgZBs'),
          ),
        ]),

        const SizedBox(height: 16),

        // ── Keyboard shortcuts (desktop) ─────────────────────────────────
        SettingsSection(label: L.aboutShortcuts, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(L.aboutShortcutsSub,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ),
          _ShortcutTile(label: L.shortcutSwitchTabs, keys: 'Ctrl + 1–5'),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _ShortcutTile(label: L.shortcutSearch, keys: 'Ctrl + F'),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _ShortcutTile(label: L.shortcutClose, keys: 'Esc'),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _ShortcutTile(label: L.shortcutRefresh, keys: 'F5'),
        ]),

        const SizedBox(height: 16),

        // ── Powered by ────────────────────────────────────────────────────
        SettingsSection(label: L.aboutPoweredBy, children: [
          _PoweredByTile(
            icon: Icons.music_note_rounded,
            label: 'Last.fm API',
            url: 'https://www.last.fm/api',
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _PoweredByTile(
            icon: Icons.smart_display_rounded,
            label: 'YouTube Music',
            url: 'https://music.youtube.com',
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _PoweredByTile(
            icon: Icons.apple_rounded,
            label: 'iTunes Search API',
            url: 'https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI',
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _PoweredByTile(
            icon: Icons.graphic_eq_rounded,
            label: 'Deezer API',
            url: 'https://developers.deezer.com',
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _PoweredByTile(
            icon: Icons.storage_rounded,
            label: 'TheAudioDB',
            url: 'https://www.theaudiodb.com',
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _PoweredByTile(
            icon: Icons.album_rounded,
            label: 'MusicBrainz',
            url: 'https://musicbrainz.org',
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _PoweredByTile(
            icon: Icons.image_rounded,
            label: 'Cover Art Archive',
            url: 'https://coverartarchive.org',
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _PoweredByTile(
            icon: Icons.menu_book_rounded,
            label: 'Wikipedia / Wikimedia Commons',
            url: 'https://www.wikipedia.org',
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _PoweredByTile(
            icon: Icons.flutter_dash_rounded,
            label: 'Flutter',
            url: 'https://flutter.dev',
          ),
        ]),

        const SizedBox(height: 16),

        // ── Image disclaimer ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.image_not_supported_outlined, size: 18, color: scheme.secondary),
            const SizedBox(width: 10),
            Expanded(child: Text(
              L.aboutImageDisclaimer,
              style: text.bodySmall?.copyWith(color: scheme.onSecondaryContainer),
            )),
          ]),
        ),

        const SizedBox(height: 20),

        Center(child: Text(
          L.aboutFooter,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        )),
        const SizedBox(height: 20),
      ]),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final String label, keys;
  const _ShortcutTile({required this.label, required this.keys});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Text(keys,
            style: TextStyle(fontFamily: 'monospace', fontSize: 12,
                fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
      ),
    );
  }
}

class _SafeSvgIcon extends StatelessWidget {
  final String asset;
  final IconData fallback;
  final Color color;
  const _SafeSvgIcon({required this.asset, required this.fallback, required this.color});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: rootBundle.load(asset).then((_) => true).catchError((_) => false),
      builder: (_, snap) => snap.data == true
          ? SvgPicture.asset(asset, width: 22, height: 22,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn))
          : Icon(fallback, color: color, size: 22),
    );
  }
}

class _PoweredByTile extends StatelessWidget {
  final IconData icon;
  final String label, url;
  const _PoweredByTile({required this.icon, required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.primary, size: 22),
      title: Text(label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.open_in_new_rounded, size: 16),
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    );
  }
}