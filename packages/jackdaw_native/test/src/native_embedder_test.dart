import 'dart:io';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/jackdaw_native.dart';
import 'package:test/test.dart';

final String? _path = Platform.environment['JACKDAW_TEST_EMBED_MODEL'];

void main() {
  test(
    'retrieves on device with a native embedder and index',
    skip: _path == null ? 'set JACKDAW_TEST_EMBED_MODEL to a GGUF file' : false,
    () async {
      final model = await NativeModel.load(_path!, gpuLayers: 0);
      final embedder = await NativeEmbedder.create(model, maxTokens: 256);
      final index = NativeVectorIndex(embedder.dimensions);
      final retriever = Retriever(embedder: embedder, index: index);
      await retriever.add(const [
        Document(id: 'kestrel', text: 'The kestrel hovers over fields.'),
        Document(id: 'heron', text: 'Herons wade in rivers and spear fish.'),
        Document(id: 'tax', text: 'Quarterly tax returns are due in April.'),
      ]);
      final results = await Future.wait([
        retriever.retrieve('bird that catches fish', k: 1),
        retriever.retrieve('falcon above a meadow', k: 1),
      ]);
      expect(results.map((r) => r.single.document.id), ['heron', 'kestrel']);
      expect(embedder.id, 'local/embedder');
      await embedder.dispose();
      await expectLater(embedder.embed(['late']), throwsStateError);
      index.dispose();
      model.dispose();
    },
  );
}
