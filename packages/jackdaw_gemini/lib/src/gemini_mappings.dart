import 'package:jackdaw/jackdaw.dart';

/// Reads Gemini `usageMetadata`; thinking tokens count as output.
Usage readGeminiUsage(Map<Object?, Object?> usage) {
  final prompt = usage['promptTokenCount'];
  final output = usage['candidatesTokenCount'];
  final thoughts = usage['thoughtsTokenCount'];
  return Usage(
    inputTokens: prompt is int ? prompt : null,
    outputTokens: output is int
        ? output + (thoughts is int ? thoughts : 0)
        : null,
  );
}

/// Maps a Gemini `finishReason` to a [FinishReason].
FinishReason mapGeminiFinishReason(String reason) => switch (reason) {
  'STOP' => FinishReason.stop,
  'MAX_TOKENS' => FinishReason.length,
  'SAFETY' ||
  'RECITATION' ||
  'BLOCKLIST' ||
  'PROHIBITED_CONTENT' ||
  'SPII' ||
  'IMAGE_SAFETY' => FinishReason.contentFilter,
  _ => FinishReason.other,
};
