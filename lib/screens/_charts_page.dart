// ignore_for_file: unused_import
part of 'home_screen.dart';

class _ChartsPage extends StatefulWidget {
  final LastFmService service; const _ChartsPage({required this.service});

  @override
  State<_ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<_ChartsPage> with AutomaticKeepAliveClientMixin {
  Map<String, int>? _monthly;
  List<dynamic> _topArtists = [];
  bool _loading = true; String? _error;
  bool _gemsLoading = false; List<_GemEntry> _gems = [];

  @override bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Future.wait([
        widget.service.getMonthlyScrobbles(months: 12),
        widget.service.getTopArtists(period: 'overall', limit: 10),
      ]);
      setState(() {
        _monthly    = res[0] as Map<String, int>;
        _topArtists = res[1] as List<dynamic>;
        _loading    = false;
      });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _computeGems() async {
    if (_topArtists.isEmpty) return;
    setState(() { _gemsLoading = true; _gems = []; });
    final artists  = _topArtists.take(15).toList();
    final listeners = await Future.wait(
        artists.map((a) => widget.service.getArtistListeners((a['name'] ?? '').toString())));
    final entries = <_GemEntry>[];
    for (var i = 0; i < artists.length; i++) {
      entries.add(_GemEntry(name: (artists[i]['name'] ?? '').toString(),
          plays: int.tryParse((artists[i]['playcount'] ?? '0').toString()) ?? 0,
          listeners: listeners[i] ?? 0));
    }
    entries.sort((a, b) => a.listeners.compareTo(b.listeners));
    setState(() { _gems = entries; _gemsLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final text   = Theme.of(context).textTheme;

    if (_loading)    return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(message: _error!, onRetry: _load);

    final monthly = _monthly!;
    final maxVal  = monthly.values.fold(0, (a, b) => a > b ? a : b);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Graphiques', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        _SectionHeader(title: 'Scrobbles — 12 mois', icon: Icons.calendar_month_rounded),
        const SizedBox(height: 12),
        Card(
          elevation: 0, color: scheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: _cardBorder(scheme)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: SizedBox(height: 160, child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: monthly.entries.map((e) {
                final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
                return Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (ratio > 0) Text(_fmt(e.value), style: text.labelSmall
                        ?.copyWith(fontSize: 8, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Flexible(fit: FlexFit.loose,
                      child: FractionallySizedBox(heightFactor: ratio.clamp(0.02, 1.0),
                        child: Container(decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.45 + ratio * 0.55),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))))),
                    const SizedBox(height: 4),
                    Text(e.key.substring(5), style: text.labelSmall?.copyWith(fontSize: 9)),
                  ]),
                ));
              }).toList(),
            )),
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Top artistes — distribution', icon: Icons.mic_rounded),
        const SizedBox(height: 12),
        if (_topArtists.isNotEmpty) () {
          final mx = _topArtists.map((a) => int.tryParse((a['playcount'] ?? '0').toString()) ?? 0).fold(0, (a,b) => a>b?a:b);
          return Card(
            elevation: 0, color: scheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: _cardBorder(scheme)),
            child: Padding(padding: const EdgeInsets.all(16),
              child: Column(children: _topArtists.asMap().entries.map((e) {
                final plays = int.tryParse((e.value['playcount'] ?? '0').toString()) ?? 0;
                final ratio = mx > 0 ? plays / mx : 0.0;
                final aName = (e.value['name'] ?? '').toString();
                return GestureDetector(
                  onTap: () => showDetailSheet(context, Map<String, dynamic>.from(e.value as Map), 'artists', widget.service),
                  child: Padding(padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      SizedBox(width: 24, child: Text('${e.key + 1}',
                          textAlign: TextAlign.center, style: text.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700))),
                      const SizedBox(width: 8),
                      Expanded(flex: 3, child: Text(aName,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
                      const SizedBox(width: 8),
                      Expanded(flex: 5, child: ClipRRect(borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: ratio, minHeight: 8,
                            backgroundColor: scheme.primary.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(scheme.primary)))),
                      const SizedBox(width: 8),
                      Text(_fmt(plays), style: text.bodySmall?.copyWith(
                          color: scheme.primary, fontWeight: FontWeight.w600)),
                    ])));
              }).toList()),
            ),
          );
        }(),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Mainstream vs Pépites', icon: Icons.diamond_outlined),
        const SizedBox(height: 8),
        Text('Popularité mondiale de tes artistes favoris.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        if (_gems.isEmpty && !_gemsLoading)
          FilledButton.icon(onPressed: _computeGems,
              icon: const Icon(Icons.calculate_rounded), label: const Text('Calculer'))
        else if (_gemsLoading)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else ...[
          ..._gems.map((gem) {
            final isGem = gem.listeners < 500000;
            return Card(
              elevation: 0, color: scheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: _cardBorder(scheme)),
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: Text(isGem ? '💎' : '🎤', style: const TextStyle(fontSize: 24)),
                title: Text(gem.name, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('${_fmt(gem.listeners)} auditeurs mondiaux',
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                trailing: Text(isGem ? 'Pépite' : 'Mainstream',
                    style: text.labelSmall?.copyWith(
                        color: isGem ? scheme.tertiary : scheme.primary, fontWeight: FontWeight.w700)),
                onTap: () => showDetailSheet(
                  context,
                  {'name': gem.name},
                  'artists',
                  widget.service,
                ),
              ),
            );
          }),
          Center(child: TextButton(onPressed: _computeGems, child: const Text('Recalculer'))),
        ],
        const SizedBox(height: 20),
      ]),
    );
  }
}

class _GemEntry { final String name; final int plays, listeners;
  const _GemEntry({required this.name, required this.plays, required this.listeners}); }


// History

