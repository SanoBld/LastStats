// Shared "download + install an update" sheet, used by every update entry point.
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/extra_strings.dart';
import '../services/update_installer.dart';
import '../services/update_service.dart';
import '../theme/m3_shapes.dart';
import 'm3_components.dart';

Future<void> _openExternal(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

bool _inApp(DownloadKind k) =>
    !kIsWeb &&
    ((defaultTargetPlatform == TargetPlatform.android && k == DownloadKind.apk) ||
        (defaultTargetPlatform == TargetPlatform.windows && k == DownloadKind.installer));

/// Newer release with a downloadable file: in-app install. Otherwise: open the link.
Future<void> installOrOpen(BuildContext context, UpdateInfo info) async {
  if (info.hasDownload && UpdateService.isNewerThanInstalled(info.version)) {
    return showUpdateInstall(context, url: info.downloadUrl!, kind: info.downloadKind, version: info.version);
  }
  return _openExternal(info.hasDownload ? info.downloadUrl! : info.releaseUrl);
}

/// For links coming from news / notifications: guesses the kind from the file name.
Future<void> openUpdateUrl(BuildContext context, String url) {
  final f = url.toLowerCase().split('?').first;
  final kind = f.endsWith('.apk')
      ? DownloadKind.apk
      : f.endsWith('.exe') ? DownloadKind.installer : DownloadKind.none;
  if (kind == DownloadKind.none) return _openExternal(url);
  return showUpdateInstall(context, url: url, kind: kind);
}

Future<void> showUpdateInstall(BuildContext context,
    {required String url, required DownloadKind kind, String? version}) async {
  if (!_inApp(kind)) return _openExternal(url);
  final scheme = Theme.of(context).colorScheme;
  await showModalBottomSheet<void>(
    sheetAnimationStyle: kM3SheetAnimation,
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: scheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _UpdateSheet(url: url, kind: kind, version: version),
  );
}

enum _Phase { downloading, permission, launching, failed }

class _UpdateSheet extends StatefulWidget {
  const _UpdateSheet({required this.url, required this.kind, this.version});
  final String url;
  final DownloadKind kind;
  final String? version;

  @override
  State<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<_UpdateSheet> {
  _Phase _phase = _Phase.downloading;
  double? _p = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    setState(() { _phase = _Phase.downloading; _p = 0; });
    var r = 'fallback';
    try {
      r = await installUpdate(widget.url, widget.kind, (p) {
        if (mounted) setState(() => _p = p);
      });
    } catch (_) {}
    if (!mounted) return;
    if (r == 'ok') {
      setState(() => _phase = _Phase.launching);
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() => _phase = r == 'permission' ? _Phase.permission : _Phase.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final title = switch (_phase) {
      _Phase.downloading => tx('up_downloading'),
      _Phase.permission  => tx('up_perm_title'),
      _Phase.launching   => tx('up_installing'),
      _Phase.failed      => tx('up_failed'),
    };
    final body = switch (_phase) {
      _Phase.downloading => widget.version != null ? 'v${widget.version}' : tx('up_title'),
      _Phase.permission  => tx('up_perm_body'),
      _Phase.launching   => widget.kind == DownloadKind.installer ? tx('up_restart') : tx('up_title'),
      _Phase.failed      => tx('up_failed_body'),
    };
    final bad = _phase == _Phase.permission || _phase == _Phase.failed;
    return PopScope(
      canPop: bad,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            M3CookieBadge(
              size: 64,
              color: bad ? scheme.errorContainer : scheme.primaryContainer,
              child: Icon(
                bad ? Icons.error_outline_rounded : Icons.system_update_rounded,
                size: 30,
                color: bad ? scheme.onErrorContainer : scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            if (_phase == _Phase.downloading || _phase == _Phase.launching) ...[
              const SizedBox(height: 20),
              M3WavyProgress(
                value: _phase == _Phase.launching ? 1 : (_p ?? 0).clamp(0.0, 1.0).toDouble(),
                height: 12,
                color: scheme.primary,
                trackColor: scheme.primary.withValues(alpha: 0.18),
              ),
              if (_phase == _Phase.downloading && _p != null) ...[
                const SizedBox(height: 8),
                Text('${((_p ?? 0) * 100).round()} %',
                    style: text.labelLarge?.copyWith(
                        color: scheme.primary, fontWeight: FontWeight.w700)),
              ],
            ],
            if (bad) ...[
              const SizedBox(height: 20),
              M3TonalButton(
                width: double.infinity,
                color: scheme.primaryContainer,
                onTap: _run,
                child: Text(tx('up_retry'),
                    style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              if (_phase == _Phase.failed)
                M3TonalButton(
                  width: double.infinity,
                  color: scheme.surfaceContainerHighest,
                  onTap: () { _openExternal(widget.url); Navigator.of(context).pop(); },
                  child: Text(tx('up_browser'),
                      style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700)),
                ),
              if (_phase == _Phase.failed) const SizedBox(height: 8),
              M3TonalButton(
                width: double.infinity,
                color: scheme.surfaceContainerHighest,
                onTap: () => Navigator.of(context).pop(),
                child: Text(tx('up_close'),
                    style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
