import 'dart:io';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

const List<Document> _notes = [
  Document(id: 'zorblin', text: 'The zorblin is a bird that eats blue moss.'),
  Document(id: 'quillet', text: 'The quillet is a bird that nests in caves.'),
  Document(id: 'tarnow', text: 'The tarnow is a bird that sings at noon.'),
];

/// Claim C9: runs an agent with a retrieval tool over a native index and
/// a structured answer, all on the model at [path]. Returns a problem, or
/// `null` when every step worked.
Future<String?> offlineCheck(String path) async {
  final model = await LocalModel.open(path);
  final weights = await NativeModel.load(path, gpuLayers: 0);
  final embedder = await NativeEmbedder.create(weights);
  final index = NativeVectorIndex(embedder.dimensions);
  try {
    final retriever = Retriever(embedder: embedder, index: index);
    await retriever.add(_notes);
    final done =
        await Agent(
          model: model,
          tools: [retrievalTool(retriever, k: 1)],
          instructions:
              'Answer questions about birds by calling search_documents '
              'first, then answer from what it returns.',
          options: const GenerationOptions(maxOutputTokens: 120),
        ).complete([
          Message.user('Search the documents: what does the zorblin eat?'),
        ]);
    final found = [
      for (final m in done.messages) ...m.parts.whereType<ToolResultPart>(),
    ];
    if (found.isEmpty || !'${found.first.output}'.contains('blue moss')) {
      return 'retrieval did not return the zorblin note: $found';
    }
    if (!done.text.toLowerCase().contains('moss')) {
      return 'the answer did not use the retrieved note: ${done.text}';
    }
    await generateJson(
      model,
      [Message.user('Describe a heron.')],
      const ObjectSchema(
        properties: {'name': Schema.string(), 'eats_fish': Schema.boolean()},
        required: ['name', 'eats_fish'],
      ),
      options: const GenerationOptions(maxOutputTokens: 60),
    );
    return null;
  } finally {
    await embedder.dispose();
    index.dispose();
    weights.dispose();
    model.close();
  }
}

/// Runs the check for the GGUF model given as the only argument and exits
/// with 1 when a step fails.
Future<void> main(List<String> args) async {
  final problem = await offlineCheck(args.single);
  stdout.writeln(problem ?? 'offline agent loop: ok');
  exit(problem == null ? 0 : 1);
}
