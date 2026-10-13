@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_web/jackdaw_web.dart';
import 'package:test/test.dart';

import 'fake_wllama.dart';
import 'web_harness.dart';

Future<WebEmbedder> _open() => WebEmbedder.open(
  modelUrl: 'https://models.example/minilm.gguf',
  moduleUrl: fakeWllamaUrl(),
  wasmUrl: 'https://cdn.example/wllama.wasm',
  pooling: 'mean',
  queryPrefix: 'q: ',
  documentPrefix: 'd: ',
);

void main() {
  tearDown(() {
    globalContext['fakeError'] = null;
    globalContext['fakeEmbedShort'] = null;
  });

  test('loads for embeddings and returns unit vectors in order', () async {
    final embedder = await _open();
    expect(state('params'), {
      'n_ctx': 512,
      'embeddings': true,
      'pooling_type': 'mean',
    });
    final vectors = await embedder.embed(['abcd', 'a']);
    expect(state('embedOptions'), {
      'input': ['d: abcd', 'd: a'],
    });
    expect(vectors[0][0], closeTo(7 / 7.6158, 0.001));
    expect(vectors[1], [closeTo(0.8, 1e-6), 0, closeTo(0.6, 1e-6)]);
    await embedder.embed(['x'], kind: EmbeddingKind.query);
    expect(state('embedOptions'), {
      'input': ['q: x'],
    });
    expect(await embedder.embed(const []), isEmpty);
    expect(embedder.id, 'web/minilm.gguf');
    await embedder.close();
    expect(state('exited'), isTrue);
  });

  test('failures become provider or format errors', () async {
    final embedder = await _open();
    globalContext['fakeError'] = 'model not loaded'.toJS;
    await expectLater(embedder.embed(['a']), throwsA(isA<ProviderException>()));
    globalContext['fakeError'] = null;
    globalContext['fakeEmbedShort'] = true.toJS;
    await expectLater(embedder.embed(['a']), throwsFormatException);
  });
}
