// lib/screens/_chat_view.dart
// The conversation: message list, empty state with suggestions, composer.
part of 'home_screen.dart';

class _ChatView extends StatefulWidget {
  final Conversation chat;
  final VoidCallback? onMenu; // null on wide layouts (sidebar is always visible)
  final VoidCallback onNewChat;
  final VoidCallback onOpenModels;

  const _ChatView({
    super.key,
    required this.chat,
    required this.onMenu,
    required this.onNewChat,
    required this.onOpenModels,
  });

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  bool _hasText = false;
  List<Attachment> _files = [];

  @override
  void initState() {
    super.initState();
    ChatStore.instance.addListener(_onChange);
    ChatService.instance.addListener(_onChange);
    ModelManager.instance.addListener(_onChange);
    localeNotifier.addListener(_onChange);
    webSearchNotifier.addListener(_onChange);
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    ChatStore.instance.removeListener(_onChange);
    ChatService.instance.removeListener(_onChange);
    ModelManager.instance.removeListener(_onChange);
    localeNotifier.removeListener(_onChange);
    webSearchNotifier.removeListener(_onChange);
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    if (ChatService.instance.isGeneratingIn(widget.chat)) _scrollToEnd();
  }

  void _scrollToEnd({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final p = _scroll.position;
      if (force || p.maxScrollExtent - p.pixels < 200) {
        _scroll.jumpTo(p.maxScrollExtent);
      }
    });
  }

  Future<void> _toggleMic() async {
    final v = VoiceInput.instance;
    if (v.listening.value) return v.stop();
    final ok = await v.start(_ctrl);
    if (!ok && mounted) _toast(context, tr('voice_unavailable'));
  }

  Future<void> _attach() async {
    final picked = await Attachments.pick();
    if (picked.isNotEmpty && mounted) setState(() => _files = [..._files, ...picked]);
  }

  void _addFiles(Iterable<Attachment> list) {
    final l = list.toList();
    if (l.isNotEmpty && mounted) setState(() => _files = [..._files, ...l]);
  }

  Future<void> _onDrop(DropDoneDetails d) async {
    final out = <Attachment>[];
    for (final f in d.files) {
      final a = Attachments.fromBytes(f.name, await f.readAsBytes());
      if (a != null) out.add(a);
    }
    _addFiles(out);
    if (out.length < d.files.length && mounted) _toast(context, tr('file_unsupported'));
  }

  // Ctrl/Cmd+V with files in the clipboard: attach them instead of pasting text.
  Future<bool> _pasteFiles() async {
    if (kIsWeb) return false;
    try {
      final paths = await Pasteboard.files();
      if (paths.isEmpty) return false;
      final out = <Attachment>[];
      for (final p in paths) {
        final bytes = await File(p).readAsBytes();
        final a = Attachments.fromBytes(p.split(RegExp(r'[\\/]')).last, Uint8List.fromList(bytes));
        if (a != null) out.add(a);
      }
      _addFiles(out);
      return out.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty) return;
    if (!ChatService.instance.canChat) {
      widget.onOpenModels();
      return;
    }
    if (ChatService.instance.isGenerating) return;
    m3Haptic();
    _ctrl.clear();
    final files = _files;
    setState(() => _files = []);
    final f = ChatService.instance.send(widget.chat, text, files: files, web: webSearchNotifier.value);
    _scrollToEnd(force: true);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final service = ChatService.instance;
    final active = ModelManager.instance.active;
    final busy = service.isGeneratingIn(widget.chat);
    final messages = widget.chat.messages;

    return Scaffold(
      appBar: AppBar(
        leading: widget.onMenu == null
            ? null
            : IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.onMenu),
        automaticallyImplyLeading: false,
        titleSpacing: widget.onMenu == null ? 20 : 0,
        title: Text(
          widget.chat.title.isEmpty ? 'PicoChat' : widget.chat.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton.icon(
            onPressed: widget.onOpenModels,
            icon: const Icon(Icons.memory_rounded, size: 18),
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(active?.displayName ?? tr('select_model'), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          if (widget.onMenu != null)
            IconButton(icon: const Icon(Icons.edit_square), tooltip: tr('new_chat'), onPressed: widget.onNewChat),
          const SizedBox(width: 4),
        ],
      ),
      body: DropTarget(
        onDragDone: _onDrop,
        child: Column(children: [
        if (service.canChat && InferenceService.engine.isPlaceholder)
          Container(
            width: double.infinity,
            color: scheme.tertiaryContainer.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, size: 16, color: scheme.onTertiaryContainer),
              const SizedBox(width: 10),
              Expanded(child: Text(tr('demo_banner'), style: text.bodySmall?.copyWith(color: scheme.onTertiaryContainer))),
            ]),
          ),
        Expanded(
          child: messages.isEmpty
              ? _EmptyChat(onSuggest: _send, onOpenModels: widget.onOpenModels)
              : SelectionArea(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final m = messages[i];
                      final isLast = i == messages.length - 1;
                      // Only messages written just now slide in; old ones
                      // scrolled back into view stay still.
                      final fresh = DateTime.now().difference(m.createdAt).inMilliseconds < 2500;
                      return M3MaxWidth(
                        maxWidth: 820,
                        child: FadeSlideIn(
                          key: ValueKey(m.id),
                          skip: !fresh,
                          child: _MessageView(
                            message: m,
                            showActions: isLast && !busy && m.role == ChatRole.assistant && m.text.isNotEmpty,
                            waiting: busy && isLast && m.role == ChatRole.assistant && m.text.isEmpty,
                            generating: busy && isLast && m.role == ChatRole.assistant,
                            loadingModel: service.isLoadingModel,
                            onRegenerate: () => service.regenerate(widget.chat),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
        _composer(scheme, text, busy),
      ])),
    );
  }

  Widget _composer(ColorScheme scheme, TextTheme text, bool busy) {
    final canChat = ChatService.instance.canChat;
    final canSend = _hasText && canChat && !ChatService.instance.isGenerating;
    return SafeArea(
      top: false,
      child: M3MaxWidth(
        maxWidth: 820,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 6, 8, 6),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (_files.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(spacing: 6, children: [
                    for (final f in _files)
                      InputChip(
                        avatar: const Icon(Icons.attach_file_rounded, size: 16),
                        label: Text(f.name),
                        onDeleted: () => setState(() => _files = [..._files]..remove(f)),
                      ),
                  ]),
                ),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Focus(
                  onKeyEvent: (node, e) {
                    if (e is KeyDownEvent &&
                        e.logicalKey == LogicalKeyboardKey.keyV &&
                        (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed)) {
                      _pasteFiles().then((ok) {
                        if (!ok) {
                          Clipboard.getData(Clipboard.kTextPlain).then((t) {
                            final v = t?.text;
                            if (v == null || v.isEmpty) return;
                            final s = _ctrl.selection;
                            final at = s.isValid ? s.start : _ctrl.text.length;
                            final to = s.isValid ? s.end : _ctrl.text.length;
                            _ctrl.value = TextEditingValue(
                              text: _ctrl.text.replaceRange(at, to, v),
                              selection: TextSelection.collapsed(offset: at + v.length),
                            );
                          });
                        }
                      });
                      return KeyEventResult.handled;
                    }
                    final isEnter = e.logicalKey == LogicalKeyboardKey.enter;
                    if (isEnter &&
                        _isDesktopPlatform &&
                        sendOnEnterNotifier.value &&
                        !HardwareKeyboard.instance.isShiftPressed) {
                      if (e is KeyDownEvent) _send();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    enabled: canChat,
                    minLines: 1,
                    maxLines: 6,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: canChat ? tr('chat_hint') : tr('no_model_hint'),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedSwitcher(
                duration: M3Motion.effectsDefaultDuration,
                switchInCurve: M3Motion.spatialFast,
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
                child: busy
                    ? IconButton.filled(
                        key: const ValueKey('stop'),
                        tooltip: tr('stop'),
                        icon: const Icon(Icons.stop_rounded),
                        onPressed: ChatService.instance.requestStop,
                      )
                    : IconButton.filled(
                        key: const ValueKey('send'),
                        tooltip: tr('send'),
                        icon: const Icon(Icons.arrow_upward_rounded),
                        onPressed: canSend ? _send : null,
                      ),
              ),
              ]),
              Row(children: [
                IconButton(
                  tooltip: tr('attach_file'),
                  icon: const Icon(Icons.attach_file_rounded),
                  onPressed: canChat ? _attach : null,
                ),
                IconButton(
                  tooltip: tr('web_search'),
                  isSelected: webSearchNotifier.value,
                  icon: const Icon(Icons.public_rounded),
                  selectedIcon: const Icon(Icons.public_rounded),
                  style: webSearchNotifier.value
                      ? IconButton.styleFrom(backgroundColor: scheme.primaryContainer, foregroundColor: scheme.onPrimaryContainer)
                      : null,
                  onPressed: () {
                    webSearchNotifier.value = !webSearchNotifier.value;
                    savePref('pc_web_search', webSearchNotifier.value);
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: VoiceInput.instance.listening,
                  builder: (_, on, __) => IconButton(
                    tooltip: tr('voice_input'),
                    isSelected: on,
                    icon: Icon(on ? Icons.mic_rounded : Icons.mic_none_rounded),
                    style: on
                        ? IconButton.styleFrom(backgroundColor: scheme.primaryContainer, foregroundColor: scheme.onPrimaryContainer)
                        : null,
                    onPressed: canChat ? _toggleMic : null,
                  ),
                ),
                IconButton(
                  tooltip: tr('tools_power'),
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: () => showChatToolsSheet(context),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  final ValueChanged<String> onSuggest;
  final VoidCallback onOpenModels;
  const _EmptyChat({required this.onSuggest, required this.onOpenModels});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final canChat = ChatService.instance.canChat;
    final name = displayNameNotifier.value.trim();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FadeSlideIn(
              child: M3CookieBadge(
                size: 88,
                color: scheme.primary,
                child: BrandIcon('assets/icons/app_logo.svg', Icons.chat_bubble_rounded, size: 44, color: scheme.onPrimary),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              canChat
                  ? (name.isEmpty ? tr('empty_title') : tr('empty_title_name', {'name': name}))
                  : tr('no_model_title'),
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              canChat ? tr('empty_sub') : tr('no_model_sub'),
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            if (!canChat)
              M3LabelButton(
                kind: M3ButtonKind.filled,
                icon: Icons.download_rounded,
                label: tr('get_model'),
                onTap: onOpenModels,
              )
            else
              Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                for (final (i, k) in const ['suggest_1', 'suggest_2', 'suggest_3', 'suggest_4'].indexed)
                  FadeSlideIn(
                    delay: Duration(milliseconds: 150 + i * 70),
                    child: ActionChip(label: Text(tr(k)), onPressed: () => onSuggest(tr(k))),
                  ),
              ]),
          ]),
        ),
      ),
    );
  }
}

// ── One message ──────────────────────────────────────────────────────────────

class _MessageView extends StatelessWidget {
  final ChatMessage message;
  final bool showActions;
  final bool waiting;
  final bool generating;
  final bool loadingModel;
  final VoidCallback onRegenerate;

  const _MessageView({
    required this.message,
    required this.showActions,
    required this.waiting,
    required this.generating,
    required this.loadingModel,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (message.role == ChatRole.user) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(left: 56, top: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            for (final n in message.files)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.attach_file_rounded, size: 16, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 4),
                  Flexible(child: Text(n, style: text.labelMedium?.copyWith(color: scheme.onPrimaryContainer))),
                ]),
              ),
            Text(message.text, style: text.bodyLarge?.copyWith(color: scheme.onPrimaryContainer)),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PulseScale(
          active: generating,
          child: M3CookieBadge(
            size: 34,
            color: scheme.primary,
            child: BrandIcon('assets/icons/app_logo.svg', Icons.chat_bubble_rounded, size: 18, color: scheme.onPrimary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (waiting)
              // Loading model / searching web / first words not here yet: full-width wavy line.
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(width: double.infinity, child: M3WavyProgress(value: 1, height: 14)),
                  const SizedBox(height: 8),
                  Text(
                    loadingModel
                        ? tr('loading_model')
                        : ChatService.instance.isSearching
                            ? tr('searching_web')
                            : tr('thinking'),
                    style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ]),
              )
            else if (message.text.isNotEmpty)
              MarkdownLite(text: generating ? message.text : FileOutput.hide(message.text), style: text.bodyLarge, linkColor: scheme.primary),
            if (!generating)
              for (final f in FileOutput.extract(message.text))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _FileCard(
                    file: f,
                    onTap: () async {
                      final ok = await FileOutput.save(f);
                      if (ok && context.mounted) _toast(context, tr('file_saved'));
                    },
                  ),
                ),
            // While the answer is written, dots keep moving below the text.
            if (generating && !waiting && message.text.isNotEmpty)
              const Padding(padding: EdgeInsets.only(top: 6), child: ThinkingDots(size: 6)),
            if (message.stopped)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(tr('stopped'), style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ),
            if (message.failed)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(tr('gen_failed'), style: text.bodySmall?.copyWith(color: scheme.error)),
              ),
            if (message.memories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ActionChip(
                  avatar: const Icon(Icons.psychology_rounded, size: 18),
                  label: Text(tr('memory_saved')),
                  onPressed: () => _toast(context, message.memories.join('\n')),
                ),
              ),
            if (message.sources.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ActionChip(
                  avatar: const Icon(Icons.public_rounded, size: 18),
                  label: Text(_sourcesLabel(message.sources)),
                  onPressed: () => _showSources(context, message.sources),
                ),
              ),
            if (showActions)
              Row(children: [
                IconButton(
                  tooltip: tr('copy'),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    _toast(context, tr('copied'));
                  },
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: VoiceService.instance.speakingId,
                  builder: (_, id, __) => IconButton(
                    tooltip: tr(id == message.id ? 'voice_stop' : 'voice_read'),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(id == message.id ? Icons.stop_circle_outlined : Icons.volume_up_rounded, size: 18),
                    onPressed: () => VoiceService.instance.speak(message.id, message.text),
                  ),
                ),
                IconButton(
                  tooltip: tr('regenerate'),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: onRegenerate,
                ),
              ]),
          ]),
        ),
      ]),
    );
  }
}

// ── Web sources bubble ───────────────────────────────────────────────────────

String _sourcesLabel(List<Map<String, String>> src) {
  final names = <String>[];
  for (final s in src) {
    final d = s['domain'] ?? '';
    if (d.isNotEmpty && !names.contains(d)) names.add(d);
  }
  final first = names.take(2).join(', ');
  return src.length > 2 ? '$first +${src.length - 2}' : first;
}

void _showSources(BuildContext context, List<Map<String, String>> src) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(8, 0, 8, 16), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('${tr('sources_title')} (${src.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
          for (final s in src)
            ListTile(
              leading: const Icon(Icons.public_rounded),
              title: Text(s['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(s['domain'] ?? ''),
              onTap: () => launchUrl(Uri.parse(s['url'] ?? ''), mode: LaunchMode.externalApplication),
            ),
        ]),
      ),
    ),
  );
}


// ── File written by the AI ───────────────────────────────────────────────────

class _FileCard extends StatelessWidget {
  final GeneratedFile file;
  final VoidCallback onTap;
  const _FileCard({required this.file, required this.onTap});

  IconData _icon() {
    final e = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : '';
    if (const ['csv', 'tsv', 'xlsx'].contains(e)) return Icons.table_chart_rounded;
    if (const ['json', 'xml', 'html', 'py', 'js', 'ts', 'dart', 'css', 'sql', 'java', 'kt', 'c', 'cpp'].contains(e)) {
      return Icons.code_rounded;
    }
    return Icons.description_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (!materialShapesNotifier.value) {
      return ActionChip(avatar: const Icon(Icons.download_rounded, size: 18), label: Text(file.name), onPressed: onTap);
    }
    return Material(
      color: scheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 18, 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            M3CookieBadge(size: 44, color: scheme.secondary, child: Icon(_icon(), size: 22, color: scheme.onSecondary)),
            const SizedBox(width: 12),
            Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: scheme.onSecondaryContainer)),
                Text(formatBytes(file.content.length),
                    style: text.bodySmall?.copyWith(color: scheme.onSecondaryContainer.withValues(alpha: 0.7))),
              ]),
            ),
            const SizedBox(width: 12),
            Icon(Icons.download_rounded, color: scheme.onSecondaryContainer),
          ]),
        ),
      ),
    );
  }
}
