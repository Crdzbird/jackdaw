import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

/// Measures prompt and generation speed on a fixed request.
Future<Map<String, Object>> runThroughputBench(LocalModel model) async {
  await model
      .generate(
        ModelRequest(
          messages: [Message.user('Describe the jackdaw in detail.')],
          options: const GenerationOptions(maxOutputTokens: 128),
        ),
      )
      .drain<void>();
  final stats = model.stats;
  final decodeMs = stats.totalMs - stats.promptMs;
  return {
    'promptTokens': stats.promptTokens,
    'generatedTokens': stats.generatedTokens,
    'promptTokensPerSecond': stats.promptTokens * 1000 / stats.promptMs,
    'generatedTokensPerSecond': stats.generatedTokens * 1000 / decodeMs,
    'firstTokenMs': stats.firstTokenMs,
  };
}
