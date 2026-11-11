// lib/services/chat_service.dart
// Runs one answer at a time: adds the messages, loads the model if needed,
// streams the engine output into the assistant message, handles stop,
// errors and automatic titles.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../app_state.dart';
import '../models/chat_models.dart';
import 'attachments.dart';
import 'chat_store.dart';
import 'file_output.dart';
import 'core_prompt.dart';
import 'inference_engine.dart';
import 'memory_store.dart';
import 'model_manager.dart';
import 'voice.dart';
import 'web_search.dart';

class ChatService extends ChangeNotifier {
  ChatService._();
  static final ChatService instance = ChatService._();

  bool _generating = false;
  bool _loadingModel = false;
  bool _stopRequested = false;
  bool _searching = false;
  int _loadedCtx = 0;
  String? _chatId;

  bool get isGenerating => _generating;
  bool get isLoadingModel => _loadingModel;
  bool get isSearching => _searching;
  bool isGeneratingIn(Conversation c) => _generating && _chatId == c.id;

  /// True when a model is installed and selected.
  bool get canChat => ModelManager.instance.active != null;

  Future<void> send(Conversation chat, String text,
      {List<Attachment> files = const [], bool web = false}) async {
    final clean = text.trim();
    if (clean.isEmpty || _generating || !canChat) return;
    final first = chat.messages.isEmpty;
    chat.modelId = ModelManager.instance.active!.id;
    VoiceService.instance.stop();
    final msg = ChatMessage(role: ChatRole.user, text: clean, files: [for (final f in files) f.name]);
    ChatStore.instance.addMessage(chat, msg);
    if (first && autoTitleNotifier.value) {
      ChatStore.instance.setAutoTitle(chat, _titleFrom(clean));
    }
    String? remembered;
    if (memoryEnabledNotifier.value) {
      remembered = MemoryStore.intentFact(clean);
      if (remembered != null) await MemoryStore.instance.add(remembered);
    }
    await _answer(chat, files: files, web: web, query: clean, remembered: remembered);
  }

  /// Deletes the last assistant answer and writes a new one.
  Future<void> regenerate(Conversation chat) async {
    if (_generating || !canChat) return;
    if (chat.messages.isNotEmpty && chat.messages.last.role == ChatRole.assistant) {
      ChatStore.instance.removeMessage(chat, chat.messages.last);
    }
    if (chat.messages.isEmpty || chat.messages.last.role != ChatRole.user) return;
    await _answer(chat);
  }

  /// Called by the stop button.
  void requestStop() {
    if (!_generating) return;
    _stopRequested = true;
    InferenceService.engine.stop();
  }

  Future<void> _answer(Conversation chat,
      {List<Attachment> files = const [], bool web = false, String query = '', String? remembered}) async {
    final store = ChatStore.instance;
    final engine = InferenceService.engine;
    final model = ModelManager.instance.active;
    if (model == null) return;

    final history = List<ChatMessage>.of(chat.messages); // ends with the user message
    final reply = ChatMessage(role: ChatRole.assistant, text: '');
    store.addMessage(chat, reply);

    _generating = true;
    _chatId = chat.id;
    _stopRequested = false;
    notifyListeners();

    final lastUser = history.lastWhere((m) => m.role == ChatRole.user, orElse: () => ChatMessage(role: ChatRole.user, text: '')).text;
    final wantsFile = FileOutput.requested(lastUser);
    String shown(String t) {
      final v = MemoryStore.visible(t.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '').replaceAll(RegExp(r'<think>[\s\S]*$'), ''));
      return wantsFile ? v : FileOutput.strip(v);
    }
    final buffer = StringBuffer();
    var lastPush = DateTime.fromMillisecondsSinceEpoch(0);
    try {
      // Files + web results go into a hidden context of the user message.
      if (files.isNotEmpty || (web && query.isNotEmpty)) {
        final budget = ((contextSizeNotifier.value - maxTokensNotifier.value - 500) * 3).clamp(1500, 60000);
        final ctx = StringBuffer();
        for (final f in files) {
          final cut = budget ~/ files.length;
          final t = f.text.length > cut ? f.text.substring(0, cut) : f.text;
          ctx.writeln('--- File: ${f.name} ---\n$t\n');
        }
        if (web && query.isNotEmpty) {
          _searching = true;
          notifyListeners();
          final found = await WebSearch.run(query, max: webMaxSourcesNotifier.value);
          _searching = false;
          if (found.isNotEmpty) {
            final r = WebSearch.format(found, budget ~/ 2);
            reply.sources = [for (final w in found) {'title': w.title, 'url': w.url, 'domain': w.domain}];
            ctx.writeln('--- Web results (use them and cite the URLs) ---\n$r\n');
          }
        }
        for (var i = history.length - 1; i >= 0; i--) {
          if (history[i].role == ChatRole.user) {
            history[i].context = ctx.toString();
            break;
          }
        }
      }
      if (engine.loadedModelId != model.id || _loadedCtx != contextSizeNotifier.value) {
        _loadingModel = true;
        notifyListeners();
        await engine.load(model, contextSize: contextSizeNotifier.value);
        _loadedCtx = contextSizeNotifier.value;
        _loadingModel = false;
        notifyListeners();
      }
      final options = GenerationOptions(
        systemPrompt: CorePrompt.build(fileRequested: wantsFile),
        temperature: temperatureNotifier.value,
        maxTokens: maxTokensNotifier.value,
      );
      await for (final piece in engine.generate(history, options)) {
        buffer.write(piece);
        if (streamResponsesNotifier.value) {
          reply.text = shown(buffer.toString());
          final now = DateTime.now();
          if (now.difference(lastPush).inMilliseconds > 40) {
            lastPush = now;
            store.messageChanged(chat);
          }
        }
      }
      if (remembered != null) {
        reply.memories = [remembered];
      } else if (memoryEnabledNotifier.value) {
        reply.memories = await MemoryStore.instance.harvest(buffer.toString());
      }
      reply.text = shown(buffer.toString());
      reply.stopped = _stopRequested;
      if (autoSpeakNotifier.value && !_stopRequested && reply.text.isNotEmpty) {
        VoiceService.instance.speak(reply.id, reply.text);
      }
    } catch (e) {
      debugPrint('Generation failed: $e');
      reply.text = shown(buffer.toString());
      reply.failed = true;
    } finally {
      _loadingModel = false;
      _searching = false;
      _generating = false;
      _chatId = null;
      _stopRequested = false;
      store.messageChanged(chat);
      notifyListeners();
    }
  }

  /// First line of the message, cut to a readable length.
  String _titleFrom(String text) {
    final line = text.split('\n').first.trim();
    return line.length <= 44 ? line : '${line.substring(0, 44).trimRight()}…';
  }
}
