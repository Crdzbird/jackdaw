import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:jackdaw_web/jackdaw_web.dart';

import 'fake_wllama.dart';

/// Reads what the fake wllama recorded under [key].
Object? state(String key) =>
    (globalContext['fakeWllama']! as JSObject)[key].dartify();

/// Sets the chunks, and optionally an error, the fake will produce.
void script(List<Map<String, Object?>> chunks, {String? error}) {
  globalContext['fakeChunks'] = (jsonDecode(chunksJson(chunks)) as Object)
      .jsify();
  globalContext['fakeError'] = error?.toJS;
}

/// One streamed chunk carrying [delta].
Map<String, Object?> chunk(Map<String, Object?> delta, {String? finish}) => {
  'choices': [
    {'index': 0, 'delta': delta, 'finish_reason': finish},
  ],
};

/// Opens a [WebLocalModel] backed by the fake wllama module.
Future<WebLocalModel> openFake() => WebLocalModel.open(
  modelUrl: 'https://models.example/qwen.gguf',
  moduleUrl: fakeWllamaUrl(),
  wasmUrl: 'https://cdn.example/wllama.wasm',
  contextTokens: 2048,
);
