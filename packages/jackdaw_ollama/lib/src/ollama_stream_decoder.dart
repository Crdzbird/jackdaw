import 'package:jackdaw/jackdaw.dart';

/// Turns Ollama `/api/chat` stream chunks into model events.
final class OllamaStreamDecoder {
  /// Creates a decoder for one response.
  factory() = OllamaStreamDecoder._;

  new _();

  final StringBuffer _thinking = StringBuffer();
  int _calls = 0;
  String? _doneReason;
  int? _input;
  int? _output;

  /// Returns the events contained in one decoded [chunk].
  Iterable<ModelEvent> accept(Object? chunk) sync* {
    if (chunk case {'error': final String message}) {
      throw ProviderException(provider: 'ollama', message: message);
    }
    if (chunk case {'message': final Map<Object?, Object?> message}) {
      if (message case {'thinking': final String thinking}) {
        _thinking.write(thinking);
      }
      if (message case {'content': final String text} when text.isNotEmpty) {
        yield TextDelta(text);
      }
      if (message case {'tool_calls': final List<Object?> calls}) {
        yield* calls.map(_call).nonNulls;
      }
    }
    if (chunk case {'done': true}) {
      _doneReason = switch (chunk) {
        {'done_reason': final String reason} => reason,
        _ => null,
      };
      _input = _int(chunk, 'prompt_eval_count');
      _output = _int(chunk, 'eval_count');
    }
  }

  /// Returns the reasoning, if any, and the finish event.
  List<ModelEvent> finish() => [
    if (_thinking.isNotEmpty)
      ReasoningEvent(ReasoningPart(provider: 'ollama', text: '$_thinking')),
    FinishEvent(
      reason: _calls > 0
          ? FinishReason.toolCalls
          : switch (_doneReason) {
              'stop' => FinishReason.stop,
              'length' => FinishReason.length,
              _ => FinishReason.other,
            },
      usage: Usage(inputTokens: _input, outputTokens: _output),
    ),
  ];

  ToolCallEvent? _call(Object? call) {
    if (call case {'function': {'name': final String name}}) {
      final index = _calls++;
      final id = switch (call) {
        {'id': final String id} => id,
        _ => 'call_$index',
      };
      final arguments = switch (call) {
        {'function': {'arguments': final Object? args}} => args,
        _ => <String, Object?>{},
      };
      return ToolCallEvent(
        ToolCallPart(id: id, name: name, arguments: arguments),
      );
    }
    return null;
  }

  static int? _int(Map<Object?, Object?> chunk, String key) =>
      chunk[key] is int ? chunk[key]! as int : null;
}
