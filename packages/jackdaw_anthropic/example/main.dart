import 'dart:io';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_anthropic/jackdaw_anthropic.dart';

Future<void> main() async {
  final key = Platform.environment['ANTHROPIC_API_KEY'];
  if (key == null) {
    stderr.writeln('Set ANTHROPIC_API_KEY to run this example.');
    exitCode = 64;
    return;
  }
  final model = AnthropicModel(model: 'claude-opus-5-5', apiKey: Secret(key));
  final events = model.generate(
    ModelRequest(messages: [Message.user('Name three corvids.')]),
  );
  await for (final event in events) {
    if (event case TextDelta(:final text)) stdout.write(text);
  }
  stdout.writeln();
}
