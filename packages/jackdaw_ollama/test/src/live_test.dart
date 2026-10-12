@TestOn('vm')
library;

import 'dart:io';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_ollama/jackdaw_ollama.dart';
import 'package:test/test.dart';

final String? _model = Platform.environment['JACKDAW_OLLAMA_MODEL'];

void main() {
  test(
    'an agent runs a tool against a live Ollama server',
    skip: _model == null ? 'set JACKDAW_OLLAMA_MODEL to run' : false,
    () async {
      final weather = Tool<String>(
        name: 'get_weather',
        description: 'Current weather for a city',
        input: const ObjectSchema(
          properties: {'city': Schema.string()},
          required: ['city'],
        ),
        decode: (json) => json['city']! as String,
        run: (city) => {'city': city, 'celsius': 21},
      );
      final agent = Agent(
        model: OllamaModel(model: _model!, numCtx: 4096),
        tools: [weather],
      );
      final done = await agent.complete([Message.user('Weather in Lima?')]);
      expect(done.reason, AgentStopReason.completed);
      expect(done.messages.any((m) => m.role == Role.tool), isTrue);
      expect(done.text, contains('21'));
    },
  );
}
