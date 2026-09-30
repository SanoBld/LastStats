// README viewer + live project activity (latest release, downloads, commits,
// workflow runs). Opened from Settings > About. The README is fetched from
// GitHub (always current) and falls back to the copy bundled in the app.
import '../../l10n/extra_strings.dart';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/m3_components.dart';

const _owner = 'SanoBld';
const _repo  = 'LastStats';
const _api   = 'https://api.github.com/repos/$_owner/$_repo';


Future<dynamic> _getJson(String url) async {
  final res = await http.get(Uri.parse(url), headers: const {
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'LastStats-App',
  }).timeout(const Duration(seconds: 12));
  if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
  return jsonDecode(utf8.decode(res.bodyBytes));
}

String _ago(String iso) {
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 60) return tx('ago_min', {'n': '${diff.inMinutes.clamp(1, 59)}'});
  if (diff.inHours < 24)   return tx('ago_h', {'n': '${diff.inHours}'});
  if (diff.inDays < 30)    return tx('ago_d', {'n': '${diff.inDays}'});
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

Future<void> _open(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

class ReadmePage extends StatefulWidget {
  const ReadmePage({super.key});
  @override
  State<ReadmePage> createState() => _ReadmePageState();
}

class _ReadmePageState extends State<ReadmePage> {
  late Future<String>       _readme;
  late Future<dynamic>      _repoInfo;
  late Future<List<dynamic>> _releases;
  late Future<List<dynamic>> _commits;
  late Future<List<dynamic>> _runs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _readme = () async {
      try {
        final res = await http
            .get(Uri.parse('https://raw.githubusercontent.com/$_owner/$_repo/main/README.md'))
            .timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) return utf8.decode(res.bodyBytes);
      } catch (_) {}
      return rootBundle.loadString('README.md');
    }();
    _repoInfo = _getJson(_api);
    _releases = _getJson('$_api/releases?per_page=100').then((v) => v as List);
    _commits  = _getJson('$_api/commits?per_page=6').then((v) => v as List);
    _runs     = _getJson('$_api/actions/runs?per_page=5')
        .then((v) => (v['workflow_runs'] as List?) ?? const []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: M3AppBar(title: 'README',
                subtitle: tx('readme_sub'),),
      body: SafeArea(top: false, 
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(children: [
Expanded(
                child: RefreshIndicator(
                  onRefresh: () async { setState(_load); },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _StatsCard(repo: _repoInfo, releases: _releases),
                      const SizedBox(height: 20),
                      _Block(
                        title: 'README',
                        icon: Icons.menu_book_rounded,
                        child: FutureBuilder<String>(
                          future: _readme,
                          builder: (_, s) {
                            if (s.connectionState != ConnectionState.done) return const _Loading();
                            if (s.hasError || (s.data ?? '').isEmpty) {
                              return _Failed(onRetry: () => setState(_load));
                            }
                            return _Markdown(s.data!);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      _ListBlock(
                        title: tx('readme_commits'),
                        icon: Icons.commit_rounded,
                        future: _commits,
                        onRetry: () => setState(_load),
                        rowBuilder: (c) {
                          final m = (c['commit']?['message'] ?? '').toString().split('\n').first;
                          final who = (c['commit']?['author']?['name'] ?? '').toString();
                          final when = _ago((c['commit']?['author']?['date'] ?? '').toString());
                          return _Row(
                            icon: Icons.commit_rounded,
                            title: m,
                            subtitle: '$who · $when',
                            url: (c['html_url'] ?? '').toString(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _ListBlock(
                        title: tx('readme_workflows'),
                        icon: Icons.play_circle_outline_rounded,
                        future: _runs,
                        onRetry: () => setState(_load),
                        rowBuilder: (r) {
                          final ok = (r['conclusion'] ?? '').toString();
                          final st = (r['status'] ?? '').toString();
                          final icon = ok == 'success'
                              ? Icons.check_circle_rounded
                              : ok == 'failure'
                                  ? Icons.cancel_rounded
                                  : st == 'in_progress' || st == 'queued'
                                      ? Icons.hourglass_top_rounded
                                      : Icons.remove_circle_outline_rounded;
                          return _Row(
                            icon: icon,
                            title: (r['name'] ?? r['display_title'] ?? '').toString(),
                            subtitle: '${r['head_branch'] ?? ''} · ${_ago((r['updated_at'] ?? '').toString())}',
                            url: (r['html_url'] ?? '').toString(),
                            good: ok == 'success',
                            bad: ok == 'failure',
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      FilledButton.tonalIcon(
                        onPressed: () => _open('https://github.com/$_owner/$_repo'),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: Text(tx('readme_github')),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Stats: version, downloads, stars, license ──────────────────────────────
class _StatsCard extends StatelessWidget {
  final Future<dynamic> repo;
  final Future<List<dynamic>> releases;
  const _StatsCard({required this.repo, required this.releases});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: FutureBuilder<List<dynamic>>(
        future: Future.wait<dynamic>([repo.catchError((_) => null), releases.catchError((_) => <dynamic>[])]),
        builder: (_, s) {
          if (s.connectionState != ConnectionState.done) {
            return const SizedBox(height: 72, child: _Loading());
          }
          final info = s.data?[0] as Map?;
          final rel  = (s.data?[1] as List?) ?? const [];
          final latest = rel.cast<Map>().where((r) => r['draft'] != true).firstOrNull;
          var downloads = 0;
          for (final r in rel.cast<Map>()) {
            for (final a in (r['assets'] as List? ?? const [])) {
              downloads += ((a as Map)['download_count'] as num?)?.toInt() ?? 0;
            }
          }
          Widget stat(IconData i, String label, String value) => Expanded(
                child: Column(children: [
                  M3CookieBadge(
                    size: 44,
                    color: scheme.primary,
                    child: Icon(i, size: 22, color: scheme.onPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(value,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer)),
                  Text(label,
                      style: text.labelSmall?.copyWith(
                          color: scheme.onPrimaryContainer.withValues(alpha: 0.75))),
                ]),
              );
          if (info == null && latest == null) return _Failed(onRetry: null);
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            stat(Icons.new_releases_rounded, tx('readme_version'),
                (latest?['tag_name'] ?? '—').toString()),
            stat(Icons.download_rounded, tx('readme_downloads'), '$downloads'),
            stat(Icons.star_rounded, tx('readme_stars'),
                '${info?['stargazers_count'] ?? '—'}'),
            stat(Icons.balance_rounded, tx('readme_license'),
                (info?['license']?['spdx_id'] ?? '—').toString()),
          ]);
        },
      ),
    );
  }
}

// ── Layout helpers ─────────────────────────────────────────────────────────
class _Block extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Block({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(title, style: text.titleSmall?.copyWith(
            color: scheme.primary, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
      ),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
        ),
        child: child,
      ),
    ]);
  }
}

class _ListBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final Future<List<dynamic>> future;
  final Widget Function(Map) rowBuilder;
  final VoidCallback onRetry;
  const _ListBlock({
    required this.title, required this.icon, required this.future,
    required this.rowBuilder, required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(title, style: text.titleSmall?.copyWith(
            color: scheme.primary, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
      ),
      FutureBuilder<List<dynamic>>(
        future: future,
        builder: (_, s) {
          if (s.connectionState != ConnectionState.done) {
            return Container(
              height: 90,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const _Loading(),
            );
          }
          final items = (s.data ?? const []).whereType<Map>().toList();
          if (s.hasError || items.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(28),
              ),
              child: _Failed(onRetry: onRetry),
            );
          }
          return Column(children: [
            for (var i = 0; i < items.length; i++)
              M3SegmentTile(
                index: i,
                count: items.length,
                child: rowBuilder(items[i]),
              ),
          ]);
        },
      ),
    ]);
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, url;
  final bool good, bad;
  const _Row({
    required this.icon, required this.title, required this.subtitle,
    required this.url, this.good = false, this.bad = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final color  = bad ? scheme.error : (good ? scheme.primary : scheme.onSurfaceVariant);
    return InkWell(
      onTap: url.isEmpty ? null : () => _open(url),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ]),
          ),
          const SizedBox(width: 8),
          Icon(Icons.open_in_new_rounded, size: 16, color: scheme.onSurfaceVariant),
        ]),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Center(
      child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)));
}

class _Failed extends StatelessWidget {
  final VoidCallback? onRetry;
  const _Failed({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      Icon(Icons.cloud_off_rounded, color: scheme.onSurfaceVariant),
      const SizedBox(width: 12),
      Expanded(child: Text(tx('readme_failed'),
          style: TextStyle(color: scheme.onSurfaceVariant))),
      if (onRetry != null)
        TextButton(onPressed: onRetry, child: Text(tx('readme_retry'))),
    ]);
  }
}

// ── Minimal Markdown renderer (headings, lists, code, quotes, links, bold) ──
class _Markdown extends StatefulWidget {
  final String source;
  const _Markdown(this.source);
  @override
  State<_Markdown> createState() => _MarkdownState();
}

class _MarkdownState extends State<_Markdown> {
  final List<TapGestureRecognizer> _taps = [];

  @override
  void dispose() {
    for (final t in _taps) { t.dispose(); }
    super.dispose();
  }

  static final _html  = RegExp(r'<[^>]*>');
  static final _image = RegExp(r'!\[[^\]]*\]\([^)]*\)');
  static final _inline = RegExp(r'\*\*(.+?)\*\*|`([^`]+)`|\[([^\]]+)\]\(([^)]+)\)');

  List<InlineSpan> _spans(String raw, TextStyle base, ColorScheme scheme) {
    final out = <InlineSpan>[];
    var i = 0;
    for (final m in _inline.allMatches(raw)) {
      if (m.start > i) out.add(TextSpan(text: raw.substring(i, m.start)));
      if (m.group(1) != null) {
        out.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w800)));
      } else if (m.group(2) != null) {
        out.add(TextSpan(text: m.group(2), style: TextStyle(
            fontFamily: 'monospace', backgroundColor: scheme.surfaceContainerHighest)));
      } else {
        final url = m.group(4)!;
        final tap = TapGestureRecognizer()..onTap = () {
          if (url.startsWith('http')) _open(url);
        };
        _taps.add(tap);
        out.add(TextSpan(text: m.group(3), recognizer: tap, style: TextStyle(
            color: scheme.primary, decoration: TextDecoration.underline)));
      }
      i = m.end;
    }
    if (i < raw.length) out.add(TextSpan(text: raw.substring(i)));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    for (final t in _taps) { t.dispose(); }
    _taps.clear();
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final body   = (text.bodyMedium ?? const TextStyle()).copyWith(height: 1.5);
    final blocks = <Widget>[];
    var inCode = false;
    final code = <String>[];

    Widget para(String s, {TextStyle? style, double top = 6, String? bullet}) {
      final st = style ?? body;
      return Padding(
        padding: EdgeInsets.only(top: top, left: bullet != null ? 4 : 0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (bullet != null)
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 1),
              child: Text(bullet, style: st.copyWith(color: scheme.primary, fontWeight: FontWeight.w800)),
            ),
          Expanded(child: Text.rich(TextSpan(style: st, children: _spans(s, st, scheme)))),
        ]),
      );
    }

    for (final rawLine in widget.source.split('\n')) {
      final line = rawLine.trimRight();
      if (line.trimLeft().startsWith('```')) {
        if (inCode) {
          blocks.add(Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(code.join('\n'),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ));
          code.clear();
        }
        inCode = !inCode;
        continue;
      }
      if (inCode) { code.add(line); continue; }

      var s = line.replaceAll(_image, '').replaceAll(_html, '').trim();
      if (s.isEmpty) continue;
      if (RegExp(r'^-{3,}$').hasMatch(s)) {
        blocks.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Divider(color: scheme.outlineVariant),
        ));
      } else if (s.startsWith('#')) {
        final level = s.length - s.replaceFirst(RegExp(r'^#+'), '').length;
        final st = level <= 1 ? text.headlineSmall : (level == 2 ? text.titleLarge : text.titleMedium);
        blocks.add(para(s.replaceFirst(RegExp(r'^#+\s*'), ''),
            style: st?.copyWith(fontWeight: FontWeight.w800), top: level <= 2 ? 16 : 10));
      } else if (RegExp(r'^[-*]\s+').hasMatch(s)) {
        blocks.add(para(s.replaceFirst(RegExp(r'^[-*]\s+'), ''), bullet: '•', top: 4));
      } else if (RegExp(r'^\d+\.\s+').hasMatch(s)) {
        final n = RegExp(r'^\d+').firstMatch(s)!.group(0)!;
        blocks.add(para(s.replaceFirst(RegExp(r'^\d+\.\s+'), ''), bullet: '$n.', top: 4));
      } else if (s.startsWith('>')) {
        blocks.add(Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text.rich(TextSpan(style: body, children: _spans(s.replaceFirst(RegExp(r'^>\s*'), ''), body, scheme))),
        ));
      } else if (s.startsWith('|')) {
        if (RegExp(r'^\|[\s:|-]+\|?$').hasMatch(s)) continue; // table divider
        final cells = s.split('|').map((c) => c.trim()).where((c) => c.isNotEmpty).join('  ·  ');
        blocks.add(para(cells, top: 2));
      } else {
        blocks.add(para(s));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: blocks);
  }
}
