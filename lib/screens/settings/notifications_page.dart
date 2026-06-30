// lib/screens/settings/notifications_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_state.dart';
import '../../services/notification_service.dart';
import '../../services/notification_worker.dart';

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
    // Re-register WorkManager tasks to reflect new settings
    await NotificationWorker.scheduleAll();
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
    final isEn   = localeNotifier.value == 'en';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
      ),
      body: _checkingPerm
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [

                // ── Permission banner ──────────────────────────────────────
                if (!_hasPermission) ...[
                  _PermissionBanner(isEn: isEn, onRequest: _requestPermission),
                  const SizedBox(height: 16),
                ],

                // ── WorkManager info note ──────────────────────────────────
                _InfoNote(
                  icon: Icons.info_outline_rounded,
                  text: isEn
                      ? 'Notifications run in the background via WorkManager. '
                        'The app does not need to be open. '
                        'An internet connection is required.'
                      : 'Les notifications tournent en arrière-plan via WorkManager. '
                        "L'app n'a pas besoin d'être ouverte. "
                        'Une connexion internet est nécessaire.',
                ),
                const SizedBox(height: 28),

                // ── Section: Milestones ────────────────────────────────────
                _SectionLabel(
                  isEn ? 'Scrobble milestones' : 'Jalons de scrobbles',
                  scheme,
                ),
                const SizedBox(height: 10),

                // Grand milestones card
                _NotifCard(
                  scheme:   scheme,
                  icon:     Icons.emoji_events_rounded,
                  iconBg:   const Color(0xFFFFECB3),
                  iconFg:   const Color(0xFFE65100),
                  title:    isEn ? 'Grand milestones' : 'Grands jalons',
                  subtitle: isEn
                      ? '1K · 5K · 10K · 25K · 50K · 100K · 250K · 500K · 1M'
                      : '1K · 5K · 10K · 25K · 50K · 100K · 250K · 500K · 1M',
                  enabled:  _grandOn,
                  onToggle: _hasPermission ? _setGrand : null,
                  child: _grandOn
                      ? _GrandMilestoneInfo(isEn: isEn, scheme: scheme, text: text)
                      : null,
                ),
                const SizedBox(height: 10),

                // Interval milestone card
                _NotifCard(
                  scheme:   scheme,
                  icon:     Icons.flag_rounded,
                  iconBg:   scheme.primaryContainer,
                  iconFg:   scheme.onPrimaryContainer,
                  title:    isEn ? 'Every X scrobbles' : 'Tous les X scrobbles',
                  subtitle: isEn
                      ? 'Get notified at regular intervals'
                      : 'Notification à intervalle régulier',
                  enabled:  _milestoneOn,
                  onToggle: _hasPermission ? _setMilestone : null,
                  child: _milestoneOn
                      ? _MilestoneConfig(
                          isEn:     isEn,
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
                        )
                      : null,
                ),
                const SizedBox(height: 28),

                // ── Section: Recaps ────────────────────────────────────────
                _SectionLabel(
                  isEn ? 'Listening recaps' : 'Récapitulatifs',
                  scheme,
                ),
                const SizedBox(height: 10),

                // Daily recap
                _NotifCard(
                  scheme:   scheme,
                  icon:     Icons.today_rounded,
                  iconBg:   scheme.secondaryContainer,
                  iconFg:   scheme.onSecondaryContainer,
                  title:    isEn ? 'Daily recap' : 'Récap quotidien',
                  subtitle: isEn
                      ? 'Scrobble count + top artist for the day'
                      : 'Scrobbles du jour + artiste favori',
                  enabled:  _dailyOn,
                  onToggle: _hasPermission ? _setDaily : null,
                  child: _dailyOn
                      ? _TimePicker(
                          isEn:   isEn,
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
                        )
                      : null,
                ),
                const SizedBox(height: 10),

                // Weekly recap
                _NotifCard(
                  scheme:   scheme,
                  icon:     Icons.date_range_rounded,
                  iconBg:   scheme.tertiaryContainer,
                  iconFg:   scheme.onTertiaryContainer,
                  title:    isEn ? 'Weekly recap' : 'Récap hebdomadaire',
                  subtitle: isEn
                      ? 'Scrobble count + top artist for the week'
                      : 'Scrobbles de la semaine + artiste favori',
                  enabled:  _weeklyOn,
                  onToggle: _hasPermission ? _setWeekly : null,
                  child: _weeklyOn
                      ? _WeeklyConfig(
                          isEn:        isEn,
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
                        )
                      : null,
                ),
                const SizedBox(height: 28),

                // ── Section: News (actualités) ─────────────────────────────
                _SectionLabel(
                  isEn ? 'News' : 'Actualités',
                  scheme,
                ),
                const SizedBox(height: 10),

                _NotifCard(
                  scheme:   scheme,
                  icon:     Icons.campaign_rounded,
                  iconBg:   const Color(0xFF1D4ED8).withValues(alpha: 0.14),
                  iconFg:   const Color(0xFF1D4ED8),
                  title:    isEn ? 'News notifications' : 'Notifications d\'actualités',
                  subtitle: isEn
                      ? 'Get notified for new features, fixes and announcements'
                      : 'Soyez notifié des nouveautés, correctifs et annonces',
                  enabled:  _newsOn,
                  onToggle: _hasPermission ? _setNews : null,
                ),
                const SizedBox(height: 10),

                // Badge toggle — pure display setting, no permission needed
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(Icons.circle_notifications_rounded,
                          color: scheme.onSurfaceVariant, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          isEn ? 'Badge on the dashboard' : "Pastille sur l'accueil",
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          isEn
                              ? 'Show the unread dot on the news bell icon'
                              : "Afficher le point rouge sur la cloche d'actualités",
                          style: TextStyle(
                              fontSize: 13, color: scheme.onSurfaceVariant),
                        ),
                      ]),
                    ),
                    Switch(value: _showBadge, onChanged: _setShowBadge),
                  ]),
                ),

                const SizedBox(height: 28),

                // ── Test button ────────────────────────────────────────────
                if (_hasPermission) ...[
                  _SectionLabel(
                    isEn ? 'Test' : 'Test',
                    scheme,
                  ),
                  const SizedBox(height: 10),
                  _TestButton(
                    isEn:    isEn,
                    sent:    _testSent,
                    scheme:  scheme,
                    onTap:   _sendTest,
                  ),
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
  final bool isEn;
  final VoidCallback onRequest;
  const _PermissionBanner({required this.isEn, required this.onRequest});

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
              isEn ? 'Notifications disabled' : 'Notifications désactivées',
              style: TextStyle(
                  color: scheme.onErrorContainer, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              isEn
                  ? 'Grant permission so LastStats can send you alerts.'
                  : 'Accordez la permission pour recevoir les alertes.',
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
              child: Text(isEn ? 'Grant permission' : 'Autoriser'),
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

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String      label;
  final ColorScheme scheme;
  const _SectionLabel(this.label, this.scheme);

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
        fontSize:    12,
        fontWeight:  FontWeight.w700,
        color:       scheme.primary,
        letterSpacing: 0.6),
  );
}

// ── Notification card ─────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final ColorScheme scheme;
  final IconData    icon;
  final Color       iconBg, iconFg;
  final String      title, subtitle;
  final bool        enabled;
  final void Function(bool)? onToggle;
  final Widget? child;

  const _NotifCard({
    required this.scheme,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onToggle,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled
              ? scheme.primary.withValues(alpha: 0.35)
              : scheme.outlineVariant.withValues(alpha: 0.4),
          width: enabled ? 1.5 : 1,
        ),
      ),
      child: Column(children: [
        // Header row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: iconFg, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: text.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant, height: 1.3)),
                ],
              ),
            ),
            Switch(value: enabled, onChanged: onToggle),
          ]),
        ),

        // Expanded config section (animated)
        if (child != null) ...[
          Divider(height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.4)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: child!,
          ),
        ],
      ]),
    );
  }
}

// ── Grand milestone info box ──────────────────────────────────────────────────

class _GrandMilestoneInfo extends StatelessWidget {
  final bool        isEn;
  final ColorScheme scheme;
  final TextTheme   text;
  const _GrandMilestoneInfo({
    required this.isEn,
    required this.scheme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    // Show what each threshold message looks like
    final examples = [
      ('1,000',    isEn ? 'Your first 1,000 scrobbles. The journey begins. 🎵'
                        : 'Tes 1 000 premiers scrobbles. L\'aventure commence. 🎵'),
      ('10,000',   isEn ? 'You hit five figures! 🎉'
                        : 'Tu passes les cinq chiffres ! 🎉'),
      ('100,000',  isEn ? 'You\'re a true music addict. 🔥'
                        : 'Tu es un vrai accro à la musique. 🔥'),
      ('1,000,000',isEn ? 'One million scrobbles. That\'s legendary. 🎸'
                        : 'Un million de scrobbles. C\'est légendaire. 🎸'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEn
              ? 'You\'ll get a special notification at each of these thresholds:'
              : 'Une notification spéciale à chacun de ces paliers :',
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
                  color:        const Color(0xFFE65100).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFE65100).withValues(alpha: 0.3)),
                ),
                child: Text(
                  t,
                  style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w700,
                    color:      const Color(0xFFE65100),
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
  final bool isEn;
  final int  interval;
  final TextEditingController ctrl;
  final ColorScheme scheme;
  final TextTheme   text;
  final void Function(int) onChange;
  const _MilestoneConfig({
    required this.isEn,
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
        isEn
            ? 'Fire a notification every X scrobbles'
            : 'Envoyer une notification tous les X scrobbles',
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
            labelText:     isEn ? 'Custom value' : 'Valeur personnalisée',
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
  final bool   isEn;
  final int    hour, minute;
  final ColorScheme scheme;
  final TextTheme   text;
  final VoidCallback onTap;
  const _TimePicker({
    required this.isEn,
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
        isEn ? 'Notify at' : 'Notifier à',
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
  final bool isEn;
  final int  day, hour, minute;
  final ColorScheme  scheme;
  final TextTheme    text;
  final void Function(int) onDayChanged;
  final VoidCallback onTimeTap;
  const _WeeklyConfig({
    required this.isEn,
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
    final days = isEn
        ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        : ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        isEn ? 'Day of the week' : 'Jour de la semaine',
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
          isEn ? 'Notify at' : 'Notifier à',
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

// ── Test notification button ──────────────────────────────────────────────────

class _TestButton extends StatelessWidget {
  final bool         isEn, sent;
  final ColorScheme  scheme;
  final VoidCallback onTap;
  const _TestButton({
    required this.isEn,
    required this.sent,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            sent
                ? Icons.check_circle_rounded
                : Icons.notifications_active_rounded,
            color: sent ? Colors.green : scheme.onSurfaceVariant,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isEn ? 'Send a test notification' : 'Envoyer une notification test',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              sent
                  ? (isEn ? 'Check your notification bar!' : 'Vérifiez la barre de notifs !')
                  : (isEn ? 'Make sure everything works.' : 'Vérifiez que tout fonctionne.'),
              style: TextStyle(
                  fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ]),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: sent
              ? Padding(
                  key: const ValueKey('done'),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    isEn ? 'Sent!' : 'Envoyé !',
                    style: TextStyle(
                      color:      Colors.green,
                      fontWeight: FontWeight.w700,
                      fontSize:   13,
                    ),
                  ),
                )
              : FilledButton.tonal(
                  key:       const ValueKey('btn'),
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(isEn ? 'Send' : 'Envoyer'),
                ),
        ),
      ]),
    );
  }
}