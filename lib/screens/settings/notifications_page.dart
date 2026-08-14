// lib/screens/settings/notifications_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_state.dart';
import '../../l10n/l10n.dart';
import '../../services/notification_service.dart';
import '../../services/notification_worker.dart';
import 'settings_helpers.dart';

// ── Prefs keys (must match notification_worker.dart exactly) ─────────────────
const _kMilestoneEnabled  = 'ls_notif_milestone_enabled';
const _kMilestoneInterval = 'ls_notif_milestone_interval';
const _kGrandEnabled      = 'ls_notif_grand_enabled';
const _kDailyEnabled      = 'ls_notif_daily_enabled';
const _kDailyHour         = 'ls_notif_daily_hour';
const _kDailyMin          = 'ls_notif_daily_min';
const _kWeeklyEnabled     = 'ls_notif_weekly_enabled';
const _kWeeklyDay         = 'ls_notif_weekly_day';
const _kWeeklyHour        = 'ls_notif_weekly_hour';
const _kWeeklyMin         = 'ls_notif_weekly_min';
const _kNewsEnabled       = 'ls_notif_news_enabled';
const _kShowNewsBadge     = 'ls_show_news_badge';
const _kSyncNotifEnabled  = 'ls_notif_sync_enabled';
const _kSyncNotifDetail   = 'ls_notif_sync_progress_detail';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Permission state
  bool _hasPermission = false;
  bool _checkingPerm  = true;

  // Interval milestone
  bool _milestoneOn       = false;
  int  _milestoneInterval = 500;
  final _intervalCtrl     = TextEditingController();

  // Grand milestone (1K / 5K / 10K / … / 1M)
  bool _grandOn = true;

  // Daily recap
  bool _dailyOn   = false;
  int  _dailyHour = 21;
  int  _dailyMin  = 0;

  // Weekly recap
  bool _weeklyOn   = false;
  int  _weeklyDay  = 1; // 1 = Monday
  int  _weeklyHour = 20;
  int  _weeklyMin  = 0;

  // News (actualités) push notifications + home badge visibility
  bool _newsOn      = false;
  bool _showBadge   = true;

  // Background scrobble sync notifications
  bool _syncNotifOn     = true;
  bool _syncNotifDetail = true;

  // Test-notification feedback
  bool _testSent = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _intervalCtrl.dispose();
    super.dispose();
  }

  // ── Load / save ──────────────────────────────────────────────────────────

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final perm  = await NotificationService.hasPermission();
    if (!mounted) return;
    setState(() {
      _hasPermission     = perm;
      _checkingPerm      = false;

      _milestoneOn       = prefs.getBool(_kMilestoneEnabled)  ?? false;
      _milestoneInterval = prefs.getInt(_kMilestoneInterval)  ?? 500;
      _grandOn           = prefs.getBool(_kGrandEnabled)      ?? true;

      _dailyOn   = prefs.getBool(_kDailyEnabled) ?? false;
      _dailyHour = prefs.getInt(_kDailyHour)     ?? 21;
      _dailyMin  = prefs.getInt(_kDailyMin)      ?? 0;

      _weeklyOn   = prefs.getBool(_kWeeklyEnabled) ?? false;
      _weeklyDay  = prefs.getInt(_kWeeklyDay)      ?? 1;
      _weeklyHour = prefs.getInt(_kWeeklyHour)     ?? 20;
      _weeklyMin  = prefs.getInt(_kWeeklyMin)      ?? 0;

      _newsOn    = prefs.getBool(_kNewsEnabled)   ?? false;
      _showBadge = prefs.getBool(_kShowNewsBadge) ?? true;

      _syncNotifOn     = prefs.getBool(_kSyncNotifEnabled) ?? true;
      _syncNotifDetail = prefs.getBool(_kSyncNotifDetail)  ?? true;

      _intervalCtrl.text = _milestoneInterval.toString();
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMilestoneEnabled,  _milestoneOn);
    await prefs.setInt(_kMilestoneInterval,  _milestoneInterval);
    await prefs.setBool(_kGrandEnabled,      _grandOn);
    await prefs.setBool(_kDailyEnabled,      _dailyOn);
    await prefs.setInt(_kDailyHour,          _dailyHour);
    await prefs.setInt(_kDailyMin,           _dailyMin);
    await prefs.setBool(_kWeeklyEnabled,     _weeklyOn);
    await prefs.setInt(_kWeeklyDay,          _weeklyDay);
    await prefs.setInt(_kWeeklyHour,         _weeklyHour);
    await prefs.setInt(_kWeeklyMin,          _weeklyMin);
    await prefs.setBool(_kNewsEnabled,       _newsOn);
    notifNewsEnabledNotifier.value = _newsOn;
    await prefs.setBool(_kSyncNotifEnabled, _syncNotifOn);
    await prefs.setBool(_kSyncNotifDetail,  _syncNotifDetail);
    // Re-register WorkManager tasks to reflect new settings
    await NotificationWorker.scheduleAll();
  }

  void _setSyncNotif(bool v) {
    setState(() => _syncNotifOn = v);
    _save();
  }

  void _setSyncDetail(bool v) {
    setState(() => _syncNotifDetail = v);
    _save();
  }

  // ── Badge visibility (not a push notification, just a display toggle) ────

  Future<void> _setShowBadge(bool v) async {
    setState(() => _showBadge = v);
    showNewsBadgeNotifier.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowNewsBadge, v);
  }

  void _setNews(bool v) {
    setState(() => _newsOn = v);
    _save();
  }

  // ── Permission ───────────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final granted = await NotificationService.requestPermission();
    if (!mounted) return;
    setState(() => _hasPermission = granted);
  }

  // ── Toggle helpers ───────────────────────────────────────────────────────

  void _setMilestone(bool v) {
    setState(() => _milestoneOn = v);
    _save();
  }

  void _setGrand(bool v) {
    setState(() => _grandOn = v);
    _save();
  }

  void _setDaily(bool v) {
    setState(() => _dailyOn = v);
    _save();
  }

  void _setWeekly(bool v) {
    setState(() => _weeklyOn = v);
    _save();
  }

  // ── Time picker ──────────────────────────────────────────────────────────

  Future<void> _pickTime({
    required int hour,
    required int minute,
    required void Function(int h, int m) onPicked,
  }) async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (result != null && mounted) {
      setState(() => onPicked(result.hour, result.minute));
      _save();
    }
  }

  // ── Test notification ────────────────────────────────────────────────────

  Future<void> _sendTest() async {
    await NotificationService.showTest();
    if (!mounted) return;
    setState(() => _testSent = true);
    // Reset the feedback label after 3 s
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _testSent = false);
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(L.settingsNotifications),
        centerTitle: false,
      ),
      body: _checkingPerm
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [

                // ── Permission banner ──────────────────────────────────────
                if (!_hasPermission) ...[
                  _PermissionBanner(onRequest: _requestPermission),
                  const SizedBox(height: 16),
                ],

                // ── WorkManager info note ──────────────────────────────────
                _InfoNote(
                  icon: Icons.info_outline_rounded,
                  text: L.notifWorkManagerInfo,
                ),
                const SizedBox(height: 16),

                // ── Section: Milestones ────────────────────────────────────
                SettingsSection(label: L.onboardMilestonesSection, children: [
                  SwitchListTile(
                    secondary: Icon(Icons.emoji_events_rounded, color: scheme.primary),
                    title:    Text(L.onboardGrandMilestonesTitle),
                    subtitle: const Text('1K · 5K · 10K · 25K · 50K · 100K · 250K · 500K · 1M'),
                    value:    _grandOn,
                    onChanged: _hasPermission ? _setGrand : null,
                  ),
                  if (_grandOn) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: _GrandMilestoneInfo(scheme: scheme, text: text),
                    ),
                  ],
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Icon(Icons.flag_rounded, color: scheme.primary),
                    title:    Text(L.notifIntervalTitle),
                    subtitle: Text(L.notifIntervalSubtitle),
                    value:    _milestoneOn,
                    onChanged: _hasPermission ? _setMilestone : null,
                  ),
                  if (_milestoneOn) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: _MilestoneConfig(
                        interval: _milestoneInterval,
                        ctrl:     _intervalCtrl,
                        scheme:   scheme,
                        text:     text,
                        onChange: (v) {
                          setState(() => _milestoneInterval = v);
                          // Reset so the new interval is detected fresh
                          NotificationWorker.resetMilestoneCount();
                          _save();
                        },
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 16),

                // ── Section: Recaps ────────────────────────────────────────
                SettingsSection(label: L.notifRecapsSection, children: [
                  SwitchListTile(
                    secondary: Icon(Icons.today_rounded, color: scheme.primary),
                    title:    Text(L.onboardDailyRecapTitle),
                    subtitle: Text(L.notifDailyRecapSubtitle),
                    value:    _dailyOn,
                    onChanged: _hasPermission ? _setDaily : null,
                  ),
                  if (_dailyOn) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: _TimePicker(
                        hour:   _dailyHour,
                        minute: _dailyMin,
                        scheme: scheme,
                        text:   text,
                        onTap:  () => _pickTime(
                          hour:     _dailyHour,
                          minute:   _dailyMin,
                          onPicked: (h, m) {
                            _dailyHour = h;
                            _dailyMin  = m;
                          },
                        ),
                      ),
                    ),
                  ],
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Icon(Icons.date_range_rounded, color: scheme.primary),
                    title:    Text(L.onboardWeeklyRecapTitle),
                    subtitle: Text(L.notifWeeklyRecapSubtitle),
                    value:    _weeklyOn,
                    onChanged: _hasPermission ? _setWeekly : null,
                  ),
                  if (_weeklyOn) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: _WeeklyConfig(
                        day:         _weeklyDay,
                        hour:        _weeklyHour,
                        minute:      _weeklyMin,
                        scheme:      scheme,
                        text:        text,
                        onDayChanged: (d) {
                          setState(() => _weeklyDay = d);
                          _save();
                        },
                        onTimeTap: () => _pickTime(
                          hour:     _weeklyHour,
                          minute:   _weeklyMin,
                          onPicked: (h, m) {
                            _weeklyHour = h;
                            _weeklyMin  = m;
                          },
                        ),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 16),

                // ── Section: Scrobble sync ──────────────────────────────────
                SettingsSection(label: L.notifSyncSection, children: [
                  SwitchListTile(
                    secondary: Icon(Icons.sync_rounded, color: scheme.primary),
                    title:    Text(L.notifSyncTitle),
                    subtitle: Text(L.notifSyncSubtitle),
                    value:    _syncNotifOn,
                    onChanged: _hasPermission ? _setSyncNotif : null,
                  ),
                  if (_syncNotifOn) ...[
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: Icon(Icons.donut_large_rounded, color: scheme.primary),
                      title:    Text(L.notifSyncDetailTitle),
                      subtitle: Text(L.notifSyncDetailSubtitle),
                      value:    _syncNotifDetail,
                      onChanged: _setSyncDetail,
                    ),
                  ],
                ]),
                const SizedBox(height: 16),

                // ── Section: News (actualités) ─────────────────────────────
                SettingsSection(label: L.notifNewsSection, children: [
                  SwitchListTile(
                    secondary: Icon(Icons.campaign_rounded, color: scheme.primary),
                    title:    Text(L.onboardNewsTitle),
                    subtitle: Text(L.notifNewsSubtitle),
                    value:    _newsOn,
                    onChanged: _hasPermission ? _setNews : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Icon(Icons.circle_notifications_rounded, color: scheme.primary),
                    title:    Text(L.notifBadgeOnDashboard),
                    subtitle: Text(L.notifBadgeSubtitle),
                    value:    _showBadge,
                    onChanged: _setShowBadge,
                  ),
                ]),

                const SizedBox(height: 16),

                // ── Test button ────────────────────────────────────────────
                if (_hasPermission) ...[
                  SettingsSection(label: L.notifTestLabel, children: [
                    ListTile(
                      leading: Icon(
                        _testSent ? Icons.check_circle_rounded : Icons.notifications_active_rounded,
                        color: _testSent ? Colors.green : scheme.primary,
                      ),
                      title:    Text(L.notifSendTest),
                      subtitle: Text(_testSent ? L.notifSentCheckBar : L.notifMakeSureWorks),
                      trailing: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _testSent
                            ? Padding(
                                key: const ValueKey('done'),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(L.notifSentBang, style: const TextStyle(
                                    color: Colors.green, fontWeight: FontWeight.w700, fontSize: 13)),
                              )
                            : FilledButton.tonal(
                                key:       const ValueKey('btn'),
                                onPressed: _sendTest,
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                child: Text(L.notifSendButton),
                              ),
                      ),
                    ),
                  ]),
                ],

                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

// ── Permission banner ─────────────────────────────────────────────────────────

class _PermissionBanner extends StatelessWidget {
  final VoidCallback onRequest;
  const _PermissionBanner({required this.onRequest});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.notifications_off_rounded,
            color: scheme.onErrorContainer, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              L.notifPermissionDisabledTitle,
              style: TextStyle(
                  color: scheme.onErrorContainer, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              L.notifPermissionDisabledBody,
              style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: onRequest,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.onErrorContainer,
                foregroundColor: scheme.errorContainer,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(L.notifGrantPermission),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Info note ─────────────────────────────────────────────────────────────────

class _InfoNote extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _InfoNote({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
                fontSize: 13, color: scheme.onSurfaceVariant, height: 1.4),
          ),
        ),
      ]),
    );
  }
}

// ── Grand milestone info box ──────────────────────────────────────────────────

class _GrandMilestoneInfo extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme   text;
  const _GrandMilestoneInfo({
    required this.scheme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    // Show what each threshold message looks like
    final msgs = L.notifThresholdMessages;
    final examples = [
      ('1,000',     msgs[0]),
      ('10,000',    msgs[1]),
      ('100,000',   msgs[2]),
      ('1,000,000', msgs[3]),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L.notifThresholdIntro,
          style: text.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 10),
        // Threshold chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in ['1K', '5K', '10K', '25K', '50K',
                             '100K', '250K', '500K', '1M'])
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:        scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  t,
                  style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w700,
                    color:      scheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Preview examples
        for (final e in examples) ...[
          _ExampleRow(count: e.$1, msg: e.$2, scheme: scheme, text: text),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

// ── Single example row inside grand milestone info ────────────────────────────

class _ExampleRow extends StatelessWidget {
  final String      count, msg;
  final ColorScheme scheme;
  final TextTheme   text;
  const _ExampleRow({
    required this.count,
    required this.msg,
    required this.scheme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          count,
          style: TextStyle(
            fontSize:   11,
            fontWeight: FontWeight.w700,
            color:      scheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          msg,
          style: text.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant, height: 1.3),
        ),
      ),
    ]);
  }
}

// ── Interval milestone config: quick chips + custom text field ────────────────

class _MilestoneConfig extends StatelessWidget {
  final int  interval;
  final TextEditingController ctrl;
  final ColorScheme scheme;
  final TextTheme   text;
  final void Function(int) onChange;
  const _MilestoneConfig({
    required this.interval,
    required this.ctrl,
    required this.scheme,
    required this.text,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        L.notifIntervalDescription,
        style: text.bodySmall
            ?.copyWith(color: scheme.onSurfaceVariant, height: 1.3),
      ),
      const SizedBox(height: 10),
      // Quick-pick chips
      Wrap(
        spacing: 6,
        children: [
          for (final v in [100, 250, 500, 1000])
            FilterChip(
              label:         Text('$v'),
              selected:      interval == v,
              visualDensity: VisualDensity.compact,
              onSelected:    (_) {
                ctrl.text = '$v';
                onChange(v);
              },
            ),
        ],
      ),
      const SizedBox(height: 10),
      // Custom value field
      SizedBox(
        height: 44,
        child: TextField(
          controller:   ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText:     L.notifCustomValueLabel,
            border:        const OutlineInputBorder(),
            isDense:       true,
            suffixText:    'scrobbles',
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
          ),
          onSubmitted: (v) {
            final parsed = int.tryParse(v);
            if (parsed != null && parsed > 0) onChange(parsed);
          },
        ),
      ),
    ]);
  }
}

// ── Time picker row ───────────────────────────────────────────────────────────

class _TimePicker extends StatelessWidget {
  final int    hour, minute;
  final ColorScheme scheme;
  final TextTheme   text;
  final VoidCallback onTap;
  const _TimePicker({
    required this.hour,
    required this.minute,
    required this.scheme,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return Row(children: [
      Text(
        L.notifTimeNotifyAt,
        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      const SizedBox(width: 12),
      FilledButton.tonal(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text(
          '$hh:$mm',
          style: const TextStyle(
            fontWeight:   FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    ]);
  }
}

// ── Weekly config: day chips + time picker ────────────────────────────────────

class _WeeklyConfig extends StatelessWidget {
  final int  day, hour, minute;
  final ColorScheme  scheme;
  final TextTheme    text;
  final void Function(int) onDayChanged;
  final VoidCallback onTimeTap;
  const _WeeklyConfig({
    required this.day,
    required this.hour,
    required this.minute,
    required this.scheme,
    required this.text,
    required this.onDayChanged,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final days = L.weekdaysShort;
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        L.notifDayOfWeek,
        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        children: List.generate(7, (i) {
          final dayNum = i + 1;
          return FilterChip(
            label:         Text(days[i]),
            selected:      day == dayNum,
            visualDensity: VisualDensity.compact,
            onSelected:    (_) => onDayChanged(dayNum),
          );
        }),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Text(
          L.notifTimeNotifyAt,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        FilledButton.tonal(
          onPressed: onTimeTap,
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Text(
            '$hh:$mm',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ]),
    ]);
  }
}
