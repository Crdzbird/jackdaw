import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/jackdaw_native.dart';
import 'package:test/test.dart';

import 'model_fixture.dart';

Tool<Object?> _weather(List<String> asked) => Tool<Object?>(
  name: 'get_weather',
  description: 'Current weather for a city',
  input: const ObjectSchema(
    properties: {
      'city': Schema.string(description: 'City name'),
      'unit': Schema.string(enumValues: ['celsius', 'fahrenheit']),
    },
    required: ['city', 'unit'],
  ),
  decode: (json) => json,
  run: (input) {
    final args = input! as Map<String, Object?>;
    asked.add(args['city']! as String);
    return {'city': args['city'], 'temperature': 21, 'sky': 'sunny'};
  },
);

void main() {
  group(
    'tools with a model',
    skip: testModelPath == null ? noModel : false,
    () {
      late LocalModel model;

      setUpAll(() async {
        model = await LocalModel.open(testModelPath!);
      });

      tearDownAll(() => model.close());

      test('an agent calls a local tool and answers from its result', () async {
        final asked = <String>[];
        final agent = Agent(
          model: model,
          tools: [_weather(asked)],
          options: const GenerationOptions(maxOutputTokens: 160),
        );
        final done = await agent.complete([
          Message.user('What is the weather in Lima right now?'),
        ]);
        expect(done.reason, AgentStopReason.completed);
        expect(asked, ['Lima']);
        expect(done.text, contains('21'));
        final call = done.messages[1].parts.whereType<ToolCallPart>().single;
        expect(call.arguments, {
          'city': 'Lima',
          'unit': anyOf('celsius', 'fahrenheit'),
        });
      });

      test('without a need for tools the model just answers', () async {
        final agent = Agent(
          model: model,
          tools: [_weather([])],
          options: const GenerationOptions(maxOutputTokens: 40),
        );
        final done = await agent.complete([
          Message.user('Say hello in French.'),
        ]);
        expect(done.reason, AgentStopReason.completed);
        expect(done.messages.where((m) => m.role == Role.tool), isEmpty);
        expect(done.text.toLowerCase(), contains('bonjour'));
      });
    },
  );
}
