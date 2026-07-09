// lib/screens/settings/sync_page.dart
// ══════════════════════════════════════════════════════════════════════════
//  Scrobble sync settings — background auto-sync + manual sync with a
//  live progress bar (mirrors AllScrobblesService.progressNotifier, which is
//  also what the WorkManager background task drives via a system
//  notification when the app isn't in the foreground).
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/l10n.dart';
import '../../app_state.dart';
import '../../services/lastfm_service.dart';
import '../../services/all_scrobbles_service.dart';
import '../../services/notification_worker.dart';

const _kSyncEnabled   = 'ls_scrobble_sync_enabled';
const _kSyncFreqHours = 'ls_scrobble_sync_freq_hours';
const _kUsername      = 'ls_username';
const _kApiKey        = 'ls_apikey';

const List<int> _kFrequencyOptions = [1, 3, 6, 12, 24];

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  bool _enabled  = false;
  int  _freqH    = 6;
  bool _loaded   = false;

  @override
  void initState() {
    super.initState();
    localeNotifier.addListener(_rebuild);
    AllScrobblesService.progressNotifier.addListener(_rebuild);
    _load();
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_rebuild);
    AllScrobblesService.progressNotifier.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _enabled = p.getBool(_kSyncEnabled)   ?? false;
      _freqH   = p.getInt(_kSyncFreqHours)  ?? 6;
      _loaded  = true;
    });
  }

  Future<void> _setEnabled(bool v) async {
    setState(() => _enabled = v);
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSyncEnabled, v);
    await NotificationWorker.scheduleAll();
  }

  Future<void> _setFreq(int h) async {
    setState(() => _freqH = h);
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kSyncFreqHours, h);
    if (_enabled) await NotificationWorker.scheduleAll();
  }

  Future<void> _syncNow() async {
    if (AllScrobblesService.isRunning) return;
    final p        = await SharedPreferences.getInstance();
    final username = p.getString(_kUsername) ?? '';
    final apiKey   = p.getString(_kApiKey)   ?? '';
    if (username.isEmpty || apiKey.isEmpty) return;

    final service = LastFmService(apiKey: apiKey, username: username);
    if (AllScrobblesService.isFirstLoad) {
      await AllScrobblesService.loadAll(service);
    } else {
      await AllScrobblesService.syncNew(service);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;
    final progress = AllScrobblesService.progressNotifier.value;
    final isSyncing = progress.isLoading;

    final meta       = AllScrobblesService.lastCachedTimestamp;
    final lastSyncStr = meta > 0
        ? DateTime.fromMillisecondsSinceEpoch(meta * 1000).toLocal().toString().split('.').first
        : L.syncNeverLabel;
    final totalCached = AllScrobblesService.getTotalCachedScrobbles();

    return Scaffold(
      appBar: AppBar(title: Text(L.syncPageTitle)),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Auto sync section ────────────────────────────────────
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(children: [
                    SwitchListTile(
                      title: Text(L.syncAutoTitle),
                      subtitle: Text(L.syncAutoSubtitle),
                      value: _enabled,
                      onChanged: _setEnabled,
                    ),
                    if (_enabled) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(L.syncFrequencyLabel,
                              style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 10),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final h in _kFrequencyOptions)
                              ChoiceChip(
                                label: Text(h == 24 ? L.syncFrequencyDaily : L.syncFrequencyHours(h)),
                                selected: _freqH == h,
                                onSelected: (_) => _setFreq(h),
                              ),
                          ]),
                        ]),
                      ),
                    ],
                  ]),
                ),

                const SizedBox(height: 20),

                // ── Manual sync section ──────────────────────────────────
                Text(L.syncManualTitle,
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(L.syncLastSyncLabel,
                              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          Text(lastSyncStr, style: text.bodyMedium),
                        ])),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(L.syncTotalScrobblesLabel,
                              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          Text('$totalCached', style: text.bodyMedium),
                        ])),
                      ]),
                      const SizedBox(height: 16),

                      if (isSyncing) ...[
                        LinearProgressIndicator(
                          value: progress.total > 0 ? progress.fraction : null,
                        ),
                        const SizedBox(height: 8),
                        Text('${L.syncInProgress} ${progress.shortLabel}',
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      ] else ...[
                        FilledButton.icon(
                          onPressed: _syncNow,
                          icon: const Icon(Icons.sync_rounded),
                          label: Text(L.syncNowButton),
                        ),
                        if (progress.isDone) ...[
                          const SizedBox(height: 10),
                          Text(
                            progress.newCount > 0
                                ? L.syncNewScrobblesFound(progress.newCount)
                                : L.syncUpToDateMsg,
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ]),
                  ),
                ),

                const SizedBox(height: 16),
                Text(L.syncNotifNote,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
    );
  }
}
