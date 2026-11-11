// lib/screens/settings/chat_settings_page.dart
// How the assistant answers: system prompt, sampling, length, streaming.

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../l10n/l10n.dart';
import '../../services/prefs.dart';
import '../../services/reset.dart';
import '../../widgets/m3_components.dart';
import 'settings_helpers.dart';
import 'settings_rows.dart';

class ChatSettingsPage extends StatefulWidget {
  const ChatSettingsPage({super.key});

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage> {
  @override
  void initState() {
    super.initState();
    localeNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  Future<void> _reset() async {
    systemPromptNotifier.value = kDefaultSystemPrompt;
    temperatureNotifier.value = 0.7;
    maxTokensNotifier.value = 1024;
    contextSizeNotifier.value = 4096;
    streamResponsesNotifier.value = true;
    autoTitleNotifier.value = true;
    sendOnEnterNotifier.value = true;
    await savePref('pc_system_prompt', kDefaultSystemPrompt);
    await savePref('pc_temperature', 0.7);
    await savePref('pc_max_tokens', 1024);
    await savePref('pc_context_size', 4096);
    await savePref('pc_stream', true);
    await savePref('pc_auto_title', true);
    await savePref('pc_send_on_enter', true);
    if (mounted) setState(() {});
  }

  List<ChoiceOption> _intOptions(List<int> values) => [for (final v in values) ('$v', '$v', null)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: M3AppBar(title: tr('set_chat')),
      body: M3MaxWidth(
        maxWidth: 720,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          SettingsSection(label: tr('cs_behaviour'), children: [
            SettingTextRow(
              icon: Icons.psychology_rounded,
              title: tr('cs_system_prompt'),
              keyboardType: TextInputType.text,
              hint: tr('cs_system_prompt_hint'),
              value: systemPromptNotifier.value,
              onChanged: (v) {
                final clean = v.trim().isEmpty ? kDefaultSystemPrompt : v.trim();
                systemPromptNotifier.value = clean;
                savePref('pc_system_prompt', clean);
                setState(() {});
              },
            ),
            SettingSliderRow(
              icon: Icons.thermostat_rounded,
              title: tr('cs_temperature'),
              valueLabel: temperatureNotifier.value.toStringAsFixed(1),
              value: temperatureNotifier.value,
              min: 0,
              max: 2,
              divisions: 20,
              onChanged: (v) {
                temperatureNotifier.value = double.parse(v.toStringAsFixed(1));
                setState(() {});
              },
              onChangeEnd: (v) => savePref('pc_temperature', double.parse(v.toStringAsFixed(1))),
            ),
            SettingChoiceRow(
              icon: Icons.short_text_rounded,
              title: tr('cs_max_tokens'),
              description: tr('cs_max_tokens_sub'),
              options: _intOptions(const [256, 512, 1024, 2048, 4096]),
              value: '${maxTokensNotifier.value}',
              onChanged: (v) {
                maxTokensNotifier.value = int.parse(v);
                savePref('pc_max_tokens', int.parse(v));
                setState(() {});
              },
            ),
            SettingChoiceRow(
              icon: Icons.memory_rounded,
              title: tr('cs_context'),
              description: tr('cs_context_sub'),
              options: _intOptions(const [2048, 4096, 8192, 16384]),
              value: '${contextSizeNotifier.value}',
              onChanged: (v) {
                contextSizeNotifier.value = int.parse(v);
                savePref('pc_context_size', int.parse(v));
                setState(() {});
              },
            ),
          ]),
          const SizedBox(height: 20),
          SettingsSection(label: tr('cs_interface'), children: [
            SettingSwitchRow(
              icon: Icons.stream_rounded,
              title: tr('cs_stream'),
              subtitle: tr('cs_stream_sub'),
              value: streamResponsesNotifier.value,
              onChanged: (v) {
                streamResponsesNotifier.value = v;
                savePref('pc_stream', v);
                setState(() {});
              },
            ),
            SettingSwitchRow(
              icon: Icons.title_rounded,
              title: tr('cs_auto_title'),
              subtitle: tr('cs_auto_title_sub'),
              value: autoTitleNotifier.value,
              onChanged: (v) {
                autoTitleNotifier.value = v;
                savePref('pc_auto_title', v);
                setState(() {});
              },
            ),
            SettingSwitchRow(
              icon: Icons.keyboard_return_rounded,
              title: tr('cs_enter'),
              subtitle: tr('cs_enter_sub'),
              value: sendOnEnterNotifier.value,
              onChanged: (v) {
                sendOnEnterNotifier.value = v;
                savePref('pc_send_on_enter', v);
                setState(() {});
              },
            ),
          ]),
          const SizedBox(height: 20),
          SettingsSection(label: tr('cs_reset'), children: [
            SettingActionRow(icon: Icons.restart_alt_rounded, title: tr('cs_reset'), subtitle: tr('cs_reset_sub'), onTap: () async {
              if (await ResetService.confirm(context, tr('reset_settings_body'))) _reset();
            }),
          ]),
        ]),
      ),
    );
  }
}
