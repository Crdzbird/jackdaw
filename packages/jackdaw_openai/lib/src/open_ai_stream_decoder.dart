import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_openai/src/tool_call_builder.dart';

/// Turns decoded chat completion chunks into model events.
final class OpenAiStreamDecoder {
  /// Creates a decoder for one response.
  factory() = OpenAiStreamDecoder._;

  new _();

  final Map<int, ToolCallBuilder> _calls = {};
  FinishReason _reason = FinishReason.other;
  Usage _usage = const Usage();

  /// Returns the events contained in one decoded [chunk].
  Iterable<ModelEvent> accept(Object? chunk) sync* {
    if (chunk case {'usage': final Map<Object?, Object?> usage}) {
      _usage = Usage(
        inputTokens: _int(usage['prompt_tokens']),
        outputTokens: _int(usage['completion_tokens']),
      );
    }
    if (chunk case {'choices': [final Map<Object?, Object?> choice, ...]}) {
      if (choice case {'finish_reason': final String reason}) {
        _reason = _mapReason(reason);
      }
      if (choice case {'delta': {'tool_calls': final List<Object?> calls}}) {
        calls.forEach(_addCall);
      }
      if (choice case {'delta': {'content': final String text}}) {
        if (text.isNotEmpty) yield TextDelta(text);
      }
    }
  }

  /// Returns the completed tool calls followed by the finish event.
  List<ModelEvent> finish() => [
    for (final index in _calls.keys.toList()..sort())
      ToolCallEvent(_calls[index]!.build()),
    FinishEvent(reason: _reason, usage: _usage),
  ];

  void _addCall(Object? delta) {
    if (delta case {'index': final num index}) {
      final builder = _calls.putIfAbsent(index.toInt(), ToolCallBuilder.new);
      if (delta case {'id': final String id}) builder.id = id;
      if (delta case {'function': final Map<Object?, Object?> function}) {
        if (function case {'name': final String name}) builder.name = name;
        if (function case {'arguments': final String text}) {
          builder.arguments.write(text);
        }
      }
    }
  }

  static int? _int(Object? value) => value is num ? value.toInt() : null;

  static FinishReason _mapReason(String reason) => switch (reason) {
    'stop' => FinishReason.stop,
    'length' => FinishReason.length,
    'tool_calls' || 'function_call' => FinishReason.toolCalls,
    'content_filter' => FinishReason.contentFilter,
    _ => FinishReason.other,
  };
}
