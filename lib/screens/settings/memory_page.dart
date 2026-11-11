// lib/screens/settings/memory_page.dart
// See, add and delete what the AI remembers about you.
import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../../l10n/l10n.dart';
import '../../services/backup.dart';
import '../../services/memory_store.dart';
import '../../services/prefs.dart';

class MemoryPage extends StatefulWidget {
  const MemoryPage({super.key});
  @override
  State<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends State<MemoryPage> {
  final _store = MemoryStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_r);
  }

  @override
  void dispose() {
    _store.removeListener(_r);
    super.dispose();
  }

  void _r() => setState(() {});

  Future<void> _add() async {
    final c = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('memory_add')),
        content: TextField(controller: c, autofocus: true, maxLines: 3, minLines: 1),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: Text(tr('save'))),
        ],
      ),
    );
    if (v != null) await _store.add(v);
  }

  Future<void> _style() async {
    final c = TextEditingController(text: systemPromptNotifier.value);
    final v = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('ai_style')),
        content: TextField(controller: c, autofocus: true, maxLines: 4, minLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: Text(tr('save'))),
        ],
      ),
    );
    if (v == null) return;
    final clean = v.trim().isEmpty ? kDefaultSystemPrompt : v.trim();
    setState(() => systemPromptNotifier.value = clean);
    await savePref('pc_system_prompt', clean);
  }

  Future<void> _import() async {
    final r = await Backup.import();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(r == null ? 'import_failed' : 'imported'))));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('memory_title')),
        actions: [
          IconButton(tooltip: tr('import'), icon: const Icon(Icons.file_upload_outlined), onPressed: _import),
          IconButton(tooltip: tr('export'), icon: const Icon(Icons.file_download_outlined), onPressed: Backup.exportMemory),
          if (_store.items.isNotEmpty)
            IconButton(tooltip: tr('memory_clear'), icon: const Icon(Icons.delete_sweep_rounded), onPressed: _store.clear),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add_rounded)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [
        SwitchListTile(
          title: Text(tr('memory_enable')),
          subtitle: Text(tr('memory_enable_sub')),
          value: memoryEnabledNotifier.value,
          onChanged: (v) {
            setState(() => memoryEnabledNotifier.value = v);
            savePref('pc_memory', v);
          },
        ),
        ListTile(
          leading: const Icon(Icons.tune_rounded),
          title: Text(tr('ai_style')),
          subtitle: Text(systemPromptNotifier.value, maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: _style,
        ),
        if (_store.items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(tr('memory_empty'), textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          ),
        for (var i = 0; i < _store.items.length; i++)
          Card(
            elevation: 0,
            color: scheme.surfaceContainerHigh,
            child: ListTile(
              title: Text(_store.items[i]),
              trailing: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => _store.removeAt(i)),
            ),
          ),
      ]),
    );
  }
}
