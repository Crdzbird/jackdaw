import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_web/jackdaw_web.dart';

const _wllama = 'https://cdn.jsdelivr.net/npm/@wllama/wllama@3.8.1/esm';

void _show(String text) => (globalContext['document']! as JSObject)
    .getProperty<JSObject>('body'.toJS)
    .setProperty('textContent'.toJS, text.toJS);

/// An agent with a tool, run by a GGUF model in the browser. Serve an
/// instruct model, such as Qwen2.5-1.5B-Instruct, as `model.gguf` next to
/// this page.
Future<void> main() async {
  _show('Loading wllama and the model...');
  final model = await WebLocalModel.open(
    modelUrl: '${Uri.base.origin}/model.gguf',
    moduleUrl: '$_wllama/index.js',
    wasmUrl: '$_wllama/wasm/wllama.wasm',
  );
  final weather = Tool<String>(
    name: 'get_weather',
    description: 'Current weather for a city',
    input: const ObjectSchema(
      properties: {'city': Schema.string()},
      required: ['city'],
    ),
    decode: (json) => json['city']! as String,
    run: (city) => {'city': city, 'celsius': 21, 'sky': 'sunny'},
  );
  final done = await Agent(
    model: model,
    tools: [weather],
    options: const GenerationOptions(maxOutputTokens: 120),
  ).complete([Message.user('What is the weather in Lima?')]);
  final calls = [
    for (final m in done.messages) ...m.parts.whereType<ToolCallPart>(),
  ];
  _show(
    'calls: ${[for (final c in calls) '${c.name} ${c.arguments}']}\n'
    'answer: ${done.text}',
  );
}
