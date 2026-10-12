import 'dart:io';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_ollama/jackdaw_ollama.dart';

Future<void> main() async {
  final model = OllamaModel(
    model: Platform.environment['OLLAMA_MODEL'] ?? 'qwen2.5:3b-instruct',
    numCtx: 4096,
  );
  final events = model.generate(
    ModelRequest(messages: [Message.user('Name three corvids.')]),
  );
  await for (final event in events) {
    if (event case TextDelta(:final text)) stdout.write(text);
  }
  stdout.writeln();
}
