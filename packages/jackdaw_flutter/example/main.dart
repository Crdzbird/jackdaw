import 'package:flutter/material.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

/// A chat with a toy model that echoes the user; swap in `OpenAiModel`,
/// `LocalModel` or any other `LanguageModel`.
void main() {
  final chat = ChatController(
    agent: Agent(model: _Echo(), store: InMemorySessionStore()),
    sessionId: 'demo',
  );
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('jackdaw')),
        body: ChatView(controller: chat),
      ),
    ),
  );
}

final class _Echo implements LanguageModel {
  @override
  String get id => 'example/echo';

  @override
  Stream<ModelEvent> generate(ModelRequest request) async* {
    for (final word in 'You said: ${request.messages.last.text}'.split(' ')) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      yield TextDelta('$word ');
    }
    yield const FinishEvent(reason: FinishReason.stop);
  }
}
