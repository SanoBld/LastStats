// lib/screens/settings/update_history_page.dart
//
// Lists every past release: version, date, full changelog, and a direct
// download button per version — not just the newest one.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/l10n.dart';
import '../../app_state.dart';
import '../../services/update_service.dart';
import '../../widgets/markdown_lite.dart';

class UpdateHistoryPage extends StatefulWidget {
  const UpdateHistoryPage({super.key});

  @override
  State<UpdateHistoryPage> createState() => _UpdateHistoryPageState();
}

class _UpdateHistoryPageState extends State<UpdateHistoryPage> {
  List<UpdateInfo> _releases = [];
  bool             _loading  = true;
  bool             _betaChannel = false;
  // Which version numbers have their changelog expanded — latest starts open.
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _load();
    localeNotifier.addListener(_rebuild);
  }

  @override
  void dispose() { localeNotifier.removeListener(_rebuild); super.dispose(); }

  void _rebuild() => setState(() {});

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _betaChannel = p.getBool('ls_beta_channel') ?? false;
    final list = await UpdateService.fetchReleaseHistory(
      channel: _betaChannel ? UpdateChannel.beta : UpdateChannel.stable,
    );
    if (!mounted) return;
    setState(() {
      _releases = list;
      _loading  = false;
      // Latest release always expanded by default, per user request.
      if (list.isNotEmpty) _expanded.add(list.first.version);
    });
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _fmtDate(DateTime d) {
    final months = L.months;
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  IconData _downloadIcon(DownloadKind k) => switch (k) {
    DownloadKind.apk       => Icons.download_rounded,
    DownloadKind.installer => Icons.install_desktop_rounded,
    DownloadKind.zip       => Icons.folder_zip_rounded,
    DownloadKind.none      => Icons.open_in_new_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final isEn   = localeNotifier.value == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEn ? 'Version history' : 'Historique des versions'),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _releases.isEmpty
              ? Center(child: Text(
                  isEn ? 'Could not load release history.' : 'Impossible de charger l\'historique.',
                  style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _releases.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final r          = _releases[i];
                    final isLatest   = i == 0;
                    final isCurrent  = r.version == UpdateService.currentVersion;
                    final isExpanded = _expanded.contains(r.version);

                    return Container(
                      decoration: BoxDecoration(
                        color: isLatest ? scheme.tertiaryContainer.withValues(alpha: 0.5) : scheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLatest
                              ? scheme.tertiary.withValues(alpha: 0.5)
                              : scheme.outlineVariant.withValues(alpha: 0.4),
                          width: isLatest ? 1.5 : 1,
                        ),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() {
                            if (isExpanded) { _expanded.remove(r.version); }
                            else { _expanded.add(r.version); }
                          }),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Text('v${r.version}', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 8),
                                  if (isLatest) _chip(isEn ? 'LATEST' : 'DERNIÈRE', scheme.tertiary, scheme.onTertiaryContainer, scheme),
                                  if (r.isBeta)  _chip('BETA', scheme.secondary, scheme.onSecondaryContainer, scheme),
                                  if (isCurrent) _chip(isEn ? 'INSTALLED' : 'INSTALLÉE', scheme.primary, scheme.onPrimaryContainer, scheme),
                                ]),
                                if (r.publishedAt != null) ...[
                                  const SizedBox(height: 2),
                                  Text(_fmtDate(r.publishedAt!),
                                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                                ],
                              ])),
                              AnimatedRotation(
                                duration: const Duration(milliseconds: 220),
                                turns: isExpanded ? 0.5 : 0,
                                child: Icon(Icons.expand_more_rounded, color: scheme.onSurfaceVariant),
                              ),
                            ]),
                          ),
                        ),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 220),
                          sizeCurve: Curves.easeOutCubic,
                          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          firstChild: const SizedBox(width: double.infinity),
                          secondChild: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (r.notes.isNotEmpty)
                              MarkdownLite(
                                text: r.notes,
                                style: text.bodySmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.85)),
                                linkColor: scheme.primary,
                              )
                            else
                              Text(isEn ? 'No description.' : 'Aucune description.',
                                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(child: FilledButton.icon(
                                onPressed: () => _open(r.hasDownload ? r.downloadUrl! : r.releaseUrl),
                                icon: Icon(_downloadIcon(r.downloadKind), size: 18),
                                label: Text(r.hasDownload
                                    ? (isEn ? 'Download' : 'Télécharger')
                                    : (isEn ? 'View release' : 'Voir la release')),
                                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                              )),
                              if (r.hasDownload) ...[
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => _open(r.releaseUrl),
                                  child: Text(isEn ? 'Details' : 'Détails'),
                                ),
                              ],
                            ]),
                          ]),
                        )),
                      ]),
                    );
                  },
                ),
    );
  }

  Widget _chip(String label, Color bg, Color fg, ColorScheme scheme) => Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: bg.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: bg)),
  );
}
