import 'dart:convert';

import 'package:jackdaw/jackdaw.dart';

/// Builds the JSON body of a streaming Messages API request.
///
/// System messages become the top-level `system` field. Thinking blocks
/// recorded from Anthropic are replayed unchanged, as the API requires.
/// Sampling settings are sent only when set, because newer Claude models
/// reject them.
Map<String, Object?> encodeMessagesRequest(
  String model,
  ModelRequest request, {
  required int defaultMaxTokens,
}) {
  final system = [
    for (final m in request.messages)
      if (m.role == Role.system) m.text,
  ];
  return {
    'model': model,
    'max_tokens': request.options.maxOutputTokens ?? defaultMaxTokens,
    'stream': true,
    if (system.isNotEmpty) 'system': system.join('\n\n'),
    'messages': [
      for (final m in request.messages)
        if (m.role != Role.system) _message(m),
    ],
    if (request.tools.isNotEmpty)
      'tools': [for (final tool in request.tools) _tool(tool)],
    'temperature': ?request.options.temperature,
    if (request.responseSchema case final schema?)
      'output_config': {
        'format': {'type': 'json_schema', 'schema': schema.toJson()},
      },
  };
}

Map<String, Object?> _message(Message message) => {
  'role': message.role == Role.assistant ? 'assistant' : 'user',
  'content': [for (final part in message.parts) ?_block(part)],
};

Map<String, Object?>? _block(Part part) => switch (part) {
  TextPart(:final text) when text.isNotEmpty => {'type': 'text', 'text': text},
  TextPart() => null,
  ReasoningPart(provider: 'anthropic', :final data) => data,
  ReasoningPart() => null,
  ToolCallPart(:final id, :final name, :final arguments) => {
    'type': 'tool_use',
    'id': id,
    'name': name,
    'input': arguments is Map ? arguments : <String, Object?>{},
  },
  ToolResultPart(:final callId, :final output, :final isError) => {
    'type': 'tool_result',
    'tool_use_id': callId,
    'content': output is String ? output : jsonEncode(output),
    if (isError) 'is_error': true,
  },
};

Map<String, Object?> _tool(ToolSpec tool) => {
  'name': tool.name,
  'description': tool.description,
  'input_schema': tool.input.toJson(),
};
