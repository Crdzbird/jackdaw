import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jackdaw/io.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_bench/src/app/agent_chat.dart';
import 'package:jackdaw_bench/src/app/demo_tools.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

const String _session = 'demo';

/// State of [AgentChat]: restores the journal, then hands it to a
/// [ChatController] that can also show UI the agent builds.
class AgentChatState extends State<AgentChat> {
  late Future<ChatController> _chat = _open();

  Future<ChatController> _open() async {
    final store = FileSessionStore(Directory(widget.sessions)..createSync());
    final records = await store.load(_session);
    final ui = UiSurfaceController(
      basicCatalog,
      host: UiHost(allowUrl: (url) => url.scheme == 'https'),
    );
    return ChatController(
      agent: Agent(
        model: widget.model,
        store: store,
        tools: [...demoTools(widget.sessions), ui.tool()],
        instructions:
            'You are a helpful assistant running on a phone. Answer general '
            'questions yourself. Use the tools whenever the user asks about '
            'the time or about their notes, and render_ui when they ask to '
            'see a form, card, list or screen.',
        options: const GenerationOptions(maxOutputTokens: 900),
        budget: ContextBudget(
          maxTokens: 3000,
          counter: TokenCounter.fromText(widget.model.countTokens),
        ),
      ),
      sessionId: _session,
      ui: ui,
      history: [
        for (final MessageRecord(:message)
            in records.whereType<MessageRecord>())
          message,
      ],
    );
  }

  Future<void> _restart() async {
    final old = await _chat;
    await old.stop();
    final journal = File('${widget.sessions}/$_session.jsonl');
    if (journal.existsSync()) journal.deleteSync();
    if (!mounted) return;
    setState(() {
      _chat = _open();
    });
    await WidgetsBinding.instance.endOfFrame;
    await old.dispose();
  }

  @override
  void dispose() {
    _chat.then((chat) => chat.dispose()).ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ChatController>(
    future: _chat,
    builder: (context, snapshot) {
      final chat = snapshot.data;
      if (chat == null) return const Center(child: CircularProgressIndicator());
      return Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _restart,
              icon: const Icon(Icons.refresh),
              label: const Text('New chat'),
            ),
          ),
          Expanded(
            child: ChatView(controller: chat, hint: 'Ask the model'),
          ),
        ],
      );
    },
  );
}
