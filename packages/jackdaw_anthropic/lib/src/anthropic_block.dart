import 'dart:convert';

import 'package:jackdaw/jackdaw.dart';

/// One content block being streamed by the Messages API.
final class AnthropicBlock {
  /// Starts a block from its `content_block_start` payload.
  factory(Map<Object?, Object?> start) = AnthropicBlock._;

  new _(this._start);

  final Map<Object?, Object?> _start;
  final StringBuffer _content = StringBuffer();
  String _signature = '';

  /// Appends a `content_block_delta` payload; returns text to stream.
  String? add(Object? delta) {
    switch (delta) {
      case {'type': 'text_delta', 'text': final String text}:
        return text;
      case {'type': 'thinking_delta', 'thinking': final String text}:
        _content.write(text);
      case {'type': 'signature_delta', 'signature': final String signature}:
        _signature = signature;
      case {'type': 'input_json_delta', 'partial_json': final String json}:
        _content.write(json);
    }
    return null;
  }

  /// Returns the event for the finished block, if it is one jackdaw keeps.
  ModelEvent? close() => switch (_start) {
    {'type': 'thinking'} => ReasoningEvent(
      ReasoningPart(
        provider: 'anthropic',
        text: '$_content',
        data: {
          'type': 'thinking',
          'thinking': '$_content',
          'signature': _signature,
        },
      ),
    ),
    {'type': 'redacted_thinking', 'data': final String data} => ReasoningEvent(
      ReasoningPart(
        provider: 'anthropic',
        data: {'type': 'redacted_thinking', 'data': data},
      ),
    ),
    {'type': 'tool_use', 'id': final String id, 'name': final String name} =>
      ToolCallEvent(ToolCallPart(id: id, name: name, arguments: _arguments())),
    _ => null,
  };

  Object? _arguments() {
    final raw = '$_content';
    if (raw.trim().isEmpty) return <String, Object?>{};
    try {
      return jsonDecode(raw);
    } on FormatException {
      return raw;
    }
  }
}
