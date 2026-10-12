import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_anthropic/src/anthropic_block.dart';

/// Turns Messages API stream events into model events.
final class AnthropicStreamDecoder {
  /// Creates a decoder for one response.
  factory() = AnthropicStreamDecoder._;

  new _();

  final Map<int, AnthropicBlock> _blocks = {};
  FinishReason _reason = FinishReason.other;
  int? _input;
  int? _output;

  /// Returns the events contained in one decoded stream [event].
  Iterable<ModelEvent> accept(Object? event) sync* {
    switch (event) {
      case {
        'type': 'message_start',
        'message': {'usage': final Map<Object?, Object?> usage},
      }:
        _input = _inputTokens(usage);
        _output = _int(usage['output_tokens']);
      case {
        'type': 'content_block_start',
        'index': final int index,
        'content_block': final Map<Object?, Object?> block,
      }:
        _blocks[index] = AnthropicBlock(block);
        if (block case {'type': 'text', 'text': final String text}
            when text.isNotEmpty) {
          yield TextDelta(text);
        }
      case {
        'type': 'content_block_delta',
        'index': final int index,
        'delta': final Object? delta,
      }:
        if (_blocks[index]?.add(delta) case final text?) yield TextDelta(text);
      case {'type': 'content_block_stop', 'index': final int index}:
        if (_blocks.remove(index)?.close() case final done?) yield done;
      case {
        'type': 'message_delta',
        'delta': final Map<Object?, Object?> delta,
      }:
        _reason = _mapReason(delta['stop_reason']);
        if (event case {'usage': final Map<Object?, Object?> usage}) {
          _output = _int(usage['output_tokens']) ?? _output;
          _input = _inputTokens(usage) ?? _input;
        }
      case {'type': 'error', 'error': final Map<Object?, Object?> error}:
        throw _error(error);
    }
  }

  /// Returns the finish event once the stream has ended.
  List<ModelEvent> finish() => [
    FinishEvent(
      reason: _reason,
      usage: Usage(inputTokens: _input, outputTokens: _output),
    ),
  ];

  static int? _int(Object? value) => value is int ? value : null;

  static int? _inputTokens(Map<Object?, Object?> usage) {
    final base = _int(usage['input_tokens']);
    if (base == null) return null;
    return base +
        (_int(usage['cache_creation_input_tokens']) ?? 0) +
        (_int(usage['cache_read_input_tokens']) ?? 0);
  }

  static FinishReason _mapReason(Object? reason) => switch (reason) {
    'end_turn' || 'stop_sequence' => FinishReason.stop,
    'max_tokens' => FinishReason.length,
    'tool_use' => FinishReason.toolCalls,
    'refusal' => FinishReason.contentFilter,
    _ => FinishReason.other,
  };

  static ProviderException _error(Map<Object?, Object?> error) =>
      ProviderException(
        provider: 'anthropic',
        message: '${error['message'] ?? error['type']}',
        statusCode: switch (error['type']) {
          'overloaded_error' => 529,
          'rate_limit_error' => 429,
          'api_error' => 500,
          _ => null,
        },
      );
}
