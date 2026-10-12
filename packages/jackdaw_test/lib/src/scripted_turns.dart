import 'package:jackdaw/jackdaw.dart';

/// A turn that streams [chunks] of text and then stops.
List<ModelEvent> textTurn(List<String> chunks, {Usage usage = const Usage()}) =>
    [
      for (final chunk in chunks) TextDelta(chunk),
      FinishEvent(reason: FinishReason.stop, usage: usage),
    ];

/// A turn that requests [calls] and then stops for tool execution.
List<ModelEvent> toolCallTurn(
  List<ToolCallPart> calls, {
  Usage usage = const Usage(),
}) => [
  for (final call in calls) ToolCallEvent(call),
  FinishEvent(reason: FinishReason.toolCalls, usage: usage),
];
