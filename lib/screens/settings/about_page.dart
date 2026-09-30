// lib/screens/settings/about_page.dart

import '../../l10n/extra_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/l10n.dart';
import '../../app_state.dart';
import '../../services/update_service.dart';
import 'settings_helpers.dart';
import 'settings_rows.dart';
import '../../widgets/m3_components.dart';
import '../../theme/m3_motion.dart';
import 'readme_page.dart';

/// Picks the self-contained logo SVG (own background baked in): the plain
/// mono logo by default, the red-dot "Nothing" variant only when that theme
/// is active — matching brightness either way.
String _logoAsset(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final family = themeStyleNotifier.value == 'nothing' ? 'app_logo_nothing' : 'app_logo';
  return 'assets/icons/${family}_${dark ? 'black_bg' : 'white_bg'}.svg';
}

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
      appBar: M3AppBar(title: L.settingsAbout),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        // ── Logo / header ─────────────────────────────────────────────────
        Center(child: Column(children: [
          M3CookieBadge(
            size: 104,
            color: scheme.primaryContainer,
            child: SvgPicture.asset(_logoAsset(context), width: 68, height: 68),
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
              borderRadius: BorderRadius.circular(24),
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
            leading: const Icon(Icons.menu_book_rounded),
            title: Text(tx('about_readme_t'),
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(tx('about_readme_s'),
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
                M3SharedAxisRoute(builder: (_) => const ReadmePage())),
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
        _FoldSection(
          label: tx('ui_favorites'),
          children: [
            ListTile(
              leading: const Icon(Icons.library_music_rounded),
              title: const Text('Metrolist',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(tx('ui_advanced_youtube_music'), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              trailing: const Icon(Icons.open_in_new_rounded, size: 16),
              onTap: () => _open('https://github.com/MetrolistGroup/Metrolist'),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.flare_rounded),
              title: const Text('Better Nothing Music Visualizer',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(tx('ui_syncs_the_glyphs_of_no'), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              trailing: const Icon(Icons.open_in_new_rounded, size: 16),
              onTap: () => _open('https://github.com/Aleks-Levet/better-nothing-music-visualizer'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Sources / docs used to build this app ────────────────────────
        // All links below point to free, open documentation (Flutter's
        // own docs and the Material 3 spec) that guided the UI and the
        // animation work in this app.
        _FoldSection(
          label: tx('ui_sources'),
          children: [
            ListTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: const Text('Flutter documentation',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(tx('ui_official_flutter_docs_'), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              trailing: const Icon(Icons.open_in_new_rounded, size: 16),
              onTap: () => _open('https://docs.flutter.dev/'),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Material 3 — Flutter guide',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(tx('ui_official_material_3_gu'), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              trailing: const Icon(Icons.open_in_new_rounded, size: 16),
              onTap: () => _open('https://m3.material.io/develop/flutter'),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('ThemeData.useMaterial3',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(tx('ui_flutter_api_reference_'), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              trailing: const Icon(Icons.open_in_new_rounded, size: 16),
              onTap: () => _open('https://api.flutter.dev/flutter/material/ThemeData/useMaterial3.html'),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: const Text('flutter_adaptive_scaffold (pub.dev)',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(tx('ui_official_flutter_packa'), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              trailing: const Icon(Icons.open_in_new_rounded, size: 16),
              onTap: () => _open('https://pub.dev/packages/flutter_adaptive_scaffold'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Open source libraries (transparency: every package used) ────
        SettingsSection(
          label: L.aboutOpenSourceLibs,
          children: [
            SettingExpandable(
              icon: Icons.inventory_2_outlined,
              title: L.aboutOpenSourceLibsSub,
              body: Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final pkg in const [
                        'cupertino_icons', 'battery_plus', 'flutter_displaymode', 'http',
                        'dynamic_color', 'shared_preferences', 'path_provider', 'share_plus',
                        'qr_flutter', 'mobile_scanner', 'app_links', 'url_launcher',
                        'palette_generator', 'flutter_local_notifications', 'workmanager',
                        'window_manager', 'audioplayers', 'flutter_svg', 'file_picker',
                        'package_info_plus', 'crypto', 'sensors_plus', 'home_widget',
                      ])
                        ActionChip(
                          label: Text(pkg),
                          avatar: const Icon(Icons.open_in_new_rounded, size: 14),
                          onPressed: () => _open('https://pub.dev/packages/$pkg'),
                        ),
                    ]),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── License ──────────────────────────────────────────────────────
        SettingsSection(label: L.aboutLicenseSection, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(L.aboutLicenseText,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.gavel_rounded),
            title: Text(L.aboutLicenseLink,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: const Text('MIT License'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 16),
            onTap: () => _open('https://github.com/SanoBld/LastStats/blob/main/LICENSE'),
          ),
        ]),

        const SizedBox(height: 16),

        // ── AI transparency note (development) ───────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.auto_awesome_rounded, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(child: Text(
              L.aboutAiDevNote,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            )),
          ]),
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
        _FoldSection(label: L.aboutShortcuts, children: [
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
        _FoldSection(label: L.aboutPoweredBy, children: [
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
            borderRadius: BorderRadius.circular(24),
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
/// A long section folded behind a single row, so the About page stays short.
/// Same tiles as [SettingsSection]; tapping the first row shows or hides them.
class _FoldSection extends StatefulWidget {
  final String label;
  final List<Widget> children;
  const _FoldSection({required this.label, required this.children});

  @override
  State<_FoldSection> createState() => _FoldSectionState();
}

class _FoldSectionState extends State<_FoldSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items  = widget.children.where((c) => c is! Divider).toList();
    final n      = items.where((c) => c is! Padding).length;
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: M3Motion.emphasizedDecelerate,
      alignment: Alignment.topCenter,
      child: SettingsSection(
        label: widget.label,
        children: [
          ListTile(
            leading: Icon(Icons.unfold_more_rounded, color: scheme.primary),
            title: Text(
              _open
                  ? tx('fold_hide')
                  : tx('fold_show', {'n': '$n'}),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: const Duration(milliseconds: 220),
              child: const Icon(Icons.expand_more_rounded),
            ),
            onTap: () => setState(() => _open = !_open),
          ),
          if (_open) ...items,
        ],
      ),
    );
  }
}
