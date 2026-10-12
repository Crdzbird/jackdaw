import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_web/jackdaw_web.dart';

const _wllama = 'https://cdn.jsdelivr.net/npm/@wllama/wllama@3.8.1/esm';

const _schema = ObjectSchema(
  properties: {'bird': Schema.string(), 'canFly': Schema.boolean()},
  required: ['bird', 'canFly'],
);

void _show(String text) => (globalContext['document']! as JSObject)
    .getProperty<JSObject>('body'.toJS)
    .setProperty('textContent'.toJS, text.toJS);

Future<void> main() async {
  _show('Loading wllama and the model...');
  final model = await WebLocalModel.open(
    modelUrl: '${Uri.base.origin}/model.gguf',
    moduleUrl: '$_wllama/index.js',
    wasmUrl: '$_wllama/wasm/wllama.wasm',
  );
  final out = StringBuffer('Streaming: ');
  await for (final event in model.generate(
    ModelRequest(
      messages: [Message.user('In one sentence, what is a jackdaw?')],
      options: const GenerationOptions(maxOutputTokens: 48),
    ),
  )) {
    if (event case TextDelta(:final text)) _show('${out..write(text)}');
  }
  final json = await generateJson(model, [
    Message.user('Describe a jackdaw.'),
  ], _schema);
  _show('$out\n\nStructured: $json');
}
