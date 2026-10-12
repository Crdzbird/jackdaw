import 'dart:io';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_openai/jackdaw_openai.dart';

final weather = Tool<String>(
  name: 'get_weather',
  description: 'Returns the current weather for a city.',
  input: const ObjectSchema(
    properties: {'city': Schema.string(description: 'City name')},
    required: ['city'],
  ),
  decode: (json) => json['city']! as String,
  run: (city) => {'city': city, 'celsius': 21, 'sky': 'clear'},
);

Future<void> main() async {
  final env = Platform.environment;
  final baseUrl = env['OPENAI_BASE_URL'];
  final key = env['OPENAI_API_KEY'];
  final agent = Agent(
    model: OpenAiModel(
      model: env['OPENAI_MODEL'] ?? 'gpt-4o-mini',
      apiKey: key == null ? null : Secret(key),
      baseUrl: baseUrl == null ? null : Uri.parse(baseUrl),
    ),
    tools: [weather],
  );
  final history = [Message.user('What is the weather in Lima right now?')];
  await for (final event in agent.run(history)) {
    switch (event) {
      case AgentTextDelta(:final text):
        stdout.write(text);
      case AgentReasoning(:final part):
        stdout.writeln('[thinking] ${part.text}');
      case AgentToolCall(:final call):
        stdout.writeln('[call] ${call.name} ${call.arguments}');
      case AgentToolResult(:final result):
        stdout.writeln('[result] ${result.output}');
      case AgentFinished(:final usage, :final reason):
        final tokens = 'in ${usage.inputTokens} out ${usage.outputTokens}';
        stdout.writeln('\n[$reason, tokens $tokens]');
    }
  }
}
