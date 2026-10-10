// lib/screens/settings/sync_page.dart
// ══════════════════════════════════════════════════════════════════════════
//  Scrobble sync settings — background auto-sync + manual sync with a
//  live progress bar (mirrors AllScrobblesService.progressNotifier, which is
//  also what the WorkManager background task drives via a system
//  notification when the app isn't in the foreground).
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../theme/m3_motion.dart';
import '../../l10n/extra_strings.dart';
import '../../widgets/m3_components.dart';
import '../../widgets/skeleton.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/l10n.dart';
import '../../app_state.dart';
import '../../services/lastfm_service.dart';
import '../../services/all_scrobbles_service.dart';
import '../../services/notification_worker.dart';
import '../../services/friends_library_service.dart';
import 'settings_helpers.dart';
import 'settings_rows.dart';

const _kSyncEnabled   = 'ls_scrobble_sync_enabled';
const _kSyncFreqHours = 'ls_scrobble_sync_freq_hours';
const _kUsername      = 'ls_username';
const _kApiKey        = 'ls_apikey';

const List<int> _kFrequencyOptions = [1, 3, 6, 12, 24];
const List<int> _kFriendsIntervalOptions = [12, 24, 48];


class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  bool _enabled  = false;
  int  _freqH    = 6;
  bool _loaded   = false;

  int _friendsIntervalH = 24;
  List<String> _friendUsernames = [];
  bool _resyncingAll = false;

  @override
  void initState() {
    super.initState();
    localeNotifier.addListener(_rebuild);
    AllScrobblesService.progressNotifier.addListener(_rebuild);
    FriendsLibraryService.syncingNotifier.addListener(_rebuild);
    _load();
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_rebuild);
    AllScrobblesService.progressNotifier.removeListener(_rebuild);
    FriendsLibraryService.syncingNotifier.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    final friends = <String>{
      ...(p.getStringList('ls_fav_friends')  ?? []),
      ...(p.getStringList('ls_fav_profiles') ?? []),
    }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    setState(() {
      _enabled = p.getBool(_kSyncEnabled)   ?? false;
      _freqH   = p.getInt(_kSyncFreqHours)  ?? 6;
      _friendsIntervalH = FriendsLibraryService.syncIntervalHours;
      _friendUsernames  = friends;
      _loaded  = true;
    });
  }

  Future<void> _setFriendsInterval(int h) async {
    setState(() => _friendsIntervalH = h);
    await FriendsLibraryService.setSyncIntervalHours(h);
  }

  LastFmService? _buildService(SharedPreferences p) {
    final username = p.getString(_kUsername) ?? '';
    final apiKey   = p.getString(_kApiKey)   ?? '';
    if (username.isEmpty || apiKey.isEmpty) return null;
    return LastFmService(apiKey: apiKey, username: username);
  }

  Future<void> _resyncAllFriends() async {
    if (_resyncingAll || _friendUsernames.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    final service = _buildService(p);
    if (service == null) return;
    setState(() => _resyncingAll = true);
    for (final u in _friendUsernames) {
      await FriendsLibraryService.syncFriend(u, service);
    }
    if (mounted) setState(() => _resyncingAll = false);
  }

  Future<void> _resyncOneFriend(String username) async {
    final p = await SharedPreferences.getInstance();
    final service = _buildService(p);
    if (service == null) return;
    await FriendsLibraryService.syncFriend(username, service);
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
      appBar: M3AppBar(title: L.syncPageTitle),
      body: !_loaded
          ? const SkeletonList()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SettingsStatusCard(
                  on: _enabled,
                  iconOn: Icons.sync_rounded,
                  iconOff: Icons.sync_disabled_rounded,
                  title: tx(_enabled ? 'st_sync_on' : 'st_sync_off'),
                  subtitle: tx(_enabled ? 'st_sync_on_s' : 'st_sync_off_s'),
                ),
                const SizedBox(height: 16),
                // ── Auto sync section ────────────────────────────────────
                SettingsSection(label: L.syncAutoTitle, children: [
                    SwitchListTile(
                      title: Text(L.syncAutoTitle),
                      subtitle: Text(L.syncAutoSubtitle),
                      value: _enabled,
                      onChanged: _setEnabled,
                    ),
                    if (_enabled) ...[
                      const Divider(height: 1),
                      SettingChoiceRow(
                        icon: Icons.update_rounded,
                        title: L.syncFrequencyLabel,
                        options: [
                          for (final h in _kFrequencyOptions)
                            ('$h', h == 24 ? L.syncFrequencyDaily : L.syncFrequencyHours(h), null),
                        ],
                        value: '$_freqH',
                        onChanged: (v) => _setFreq(int.parse(v)),
                      ),
                    ],
                ]),

                const SizedBox(height: 20),

                // ── Manual sync section ──────────────────────────────────
                SettingsSection(label: L.syncManualTitle, children: [
                  Padding(
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

                      AnimatedSize(
                        duration: M3Motion.spatialFastDuration,
                        curve: M3Motion.emphasizedDecelerate,
                        alignment: Alignment.topCenter,
                        child: M3Switcher(child: Column(
                          key: ValueKey(isSyncing),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                      if (isSyncing) ...[
                        progress.total > 0
                            ? M3WavyProgress(value: progress.fraction)
                            : const Center(child: M3LoadingIndicator(size: 32)),
                        const SizedBox(height: 8),
                        Text('${L.syncInProgress} ${progress.shortLabel}',
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      ] else ...[
                        SettingActionGroup(items: [
                          ActionGroupItem(
                            primary: true,
                            icon: Icons.sync_rounded,
                            label: L.syncNowButton,
                            onPressed: _syncNow,
                          ),
                        ]),
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
                          ],
                        )),
                      ),
                    ]),
                  ),
                ]),

                const SizedBox(height: 20),
                SettingsSection(
                  label: tx('ui_friends_sync'),
                  children: [
                  SettingChoiceRow(
                    icon: Icons.update_rounded,
                    title: tx('ui_sync_frequency'),
                    options: [
                      for (final h in _kFriendsIntervalOptions)
                        ('$h', h == 24 ? tx('ui_daily') : '${h}h', null),
                    ],
                    value: '$_friendsIntervalH',
                    onChanged: (v) => _setFriendsInterval(int.parse(v)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SettingActionGroup(items: [
                        ActionGroupItem(
                          primary: true,
                          icon: Icons.sync_rounded,
                          label: tx('ui_resync_everyone'),
                          onPressed: _resyncingAll ? null : _resyncAllFriends,
                        ),
                      ]),
                      if (_friendUsernames.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        ..._friendUsernames.map((u) {
                          final syncing = FriendsLibraryService.isSyncing(u);
                          final has     = FriendsLibraryService.hasData(u);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(children: [
                              Expanded(child: Text(u, style: text.bodyMedium)),
                              if (syncing)
                                const SizedBox(width: 16, height: 16,
                                    child: M3Spinner())
                              else
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(has ? Icons.refresh_rounded : Icons.download_rounded,
                                      size: 20),
                                  onPressed: () => _resyncOneFriend(u),
                                ),
                            ]),
                          );
                        }),
                      ],
                    ]),
                  ),
                ]),

                const SizedBox(height: 16),
                Text(L.syncNotifNote,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
    );
  }
}
