import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_web/jackdaw_web.dart';

const _wllama = 'https://cdn.jsdelivr.net/npm/@wllama/wllama@3.8.1/esm';

void _show(String text) => (globalContext['document']! as JSObject)
    .getProperty<JSObject>('body'.toJS)
    .setProperty('textContent'.toJS, text.toJS);

/// Retrieval in the browser: serve an embedding GGUF, such as all-minilm,
/// as `model.gguf` next to this page.
Future<void> main() async {
  _show('Loading wllama and the embedding model...');
  final embedder = await WebEmbedder.open(
    modelUrl: '${Uri.base.origin}/model.gguf',
    moduleUrl: '$_wllama/index.js',
    wasmUrl: '$_wllama/wasm/wllama.wasm',
  );
  final probe = await embedder.embed(['probe']);
  final retriever = Retriever(
    embedder: embedder,
    index: FlatVectorIndex(probe.single.length),
  );
  await retriever.add(const [
    Document(id: 'kestrel', text: 'The kestrel hovers over fields.'),
    Document(id: 'heron', text: 'Herons wade in rivers and spear fish.'),
    Document(id: 'tax', text: 'Quarterly tax returns are due in April.'),
  ]);
  final hits = await retriever.retrieve('bird that catches fish', k: 2);
  _show(
    [
      for (final hit in hits)
        '${hit.document.id} ${hit.score.toStringAsFixed(3)}',
    ].join('\n'),
  );
  await embedder.close();
}
