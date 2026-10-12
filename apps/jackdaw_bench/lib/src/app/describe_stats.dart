import 'package:jackdaw_native/jackdaw_native.dart';

/// One-line summary of a finished generation for the status bar.
String describeStats(NativeStats stats) {
  final decodeMs = stats.totalMs - stats.promptMs;
  final speed = stats.generatedTokens * 1000 / decodeMs;
  return '${stats.generatedTokens} tokens, ${speed.toStringAsFixed(1)} tok/s, '
      'first token ${stats.firstTokenMs.round()} ms, '
      '${stats.reusedTokens} prompt tokens reused';
}
