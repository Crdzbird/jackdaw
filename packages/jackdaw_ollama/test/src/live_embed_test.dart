@TestOn('vm')
library;

import 'dart:io';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_ollama/jackdaw_ollama.dart';
import 'package:test/test.dart';

final String? _model = Platform.environment['JACKDAW_OLLAMA_EMBED_MODEL'];

void main() {
  test(
    'retrieval works against a live Ollama embedding model',
    skip: _model == null ? 'set JACKDAW_OLLAMA_EMBED_MODEL to run' : false,
    () async {
      final embedder = OllamaEmbedder(model: _model!);
      final probe = await embedder.embed(['probe']);
      final retriever = Retriever(
        embedder: embedder,
        index: FlatVectorIndex(probe.single.length),
      );
      await retriever.add(const [
        Document(id: 'kestrel', text: 'The kestrel hovers over fields.'),
        Document(id: 'heron', text: 'Herons wade in rivers and spear fish.'),
      ]);
      final hits = await retriever.retrieve('bird that catches fish', k: 1);
      expect(hits.single.document.id, 'heron');
    },
  );
}
