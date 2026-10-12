import 'dart:io';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

const _schema = ObjectSchema(
  properties: {
    'answer': Schema.string(),
    'confidence': Schema.number(),
    'keywords': Schema.array(items: Schema.string()),
  },
  required: ['answer', 'confidence', 'keywords'],
);

Future<double> _speed(LocalModel model, Schema? schema) async {
  await model
      .generate(
        ModelRequest(
          messages: [Message.user('What is a jackdaw and where does it live?')],
          options: const GenerationOptions(maxOutputTokens: 96),
          responseSchema: schema,
        ),
      )
      .drain<void>();
  final stats = model.stats;
  return stats.generatedTokens * 1000 / (stats.totalMs - stats.promptMs);
}

/// Compares free and grammar-constrained decoding speed on the CPU.
Future<void> main(List<String> args) async {
  final model = await LocalModel.open(
    args.single,
    options: const LocalModelOptions(gpuLayers: 0),
  );
  final free = await _speed(model, null);
  final constrained = await _speed(model, _schema);
  stdout.writeln(
    'free ${free.toStringAsFixed(1)} tok/s, '
    'grammar ${constrained.toStringAsFixed(1)} tok/s, '
    'ratio ${(constrained / free).toStringAsFixed(2)}',
  );
  model.close();
}
