import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

/// The prompt every frame measurement uses.
const String framePrompt = 'Write about jackdaws, their nests and their calls.';

/// Shows a live chat over [model] with a spinner that keeps frames coming,
/// and returns its controller.
Future<ChatController> pumpChatScreen(
  WidgetTester tester,
  LanguageModel model,
) async {
  final chat = ChatController(
    agent: Agent(
      model: model,
      store: InMemorySessionStore(),
      options: const GenerationOptions(maxOutputTokens: 200, temperature: 0),
    ),
    sessionId: 'frames',
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            ChatView(controller: chat),
            const Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return chat;
}
