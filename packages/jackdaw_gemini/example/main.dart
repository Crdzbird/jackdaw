import 'dart:io';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_gemini/jackdaw_gemini.dart';

Future<void> main() async {
  final key = Platform.environment['GEMINI_API_KEY'];
  if (key == null) {
    stderr.writeln('Set GEMINI_API_KEY to run this example.');
    exitCode = 64;
    return;
  }
  final model = GeminiModel(
    model: Platform.environment['GEMINI_MODEL'] ?? 'gemini-3.8-flash',
    apiKey: Secret(key),
  );
  final events = model.generate(
    ModelRequest(messages: [Message.user('Name three corvids.')]),
  );
  await for (final event in events) {
    if (event case TextDelta(:final text)) stdout.write(text);
  }
  stdout.writeln();
}
