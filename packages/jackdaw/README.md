# jackdaw

Agent framework for Dart and Flutter. Pre-release: the API will change.

- Codegen-free schemas that serialize for providers and validate offline.
- Typed tools: arguments are validated before your code runs; failures,
  thrown errors and timeouts go back to the model instead of crashing the run.
- An agent loop with a step limit, concurrent tool calls and summed usage.
- Streaming everywhere; cancelling a stream cancels the underlying call.
- Works on the Dart VM, Flutter, and the web (JS and Wasm builds).

```dart
import 'package:jackdaw/jackdaw.dart';

final weather = Tool<String>(
  name: 'get_weather',
  description: 'Returns the current weather for a city.',
  input: const ObjectSchema(
    properties: {'city': Schema.string()},
    required: ['city'],
  ),
  decode: (json) => json['city']! as String,
  run: (city) => {'city': city, 'celsius': 21},
);

Future<void> ask(LanguageModel model) async {
  final agent = Agent(model: model, tools: [weather]);
  final result = await agent.complete([Message.user('Weather in Lima?')]);
  print(result.text);
}
```

Models come from provider packages such as `jackdaw_openai`. For tests
without network access use `jackdaw_test`.
