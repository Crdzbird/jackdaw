import 'dart:convert';

import 'package:jackdaw/jackdaw.dart';

/// Builds the JSON body of a streaming chat completion request.
Map<String, Object?> encodeChatRequest(String model, ModelRequest request) => {
  'model': model,
  'messages': [for (final message in request.messages) ..._message(message)],
  if (request.tools.isNotEmpty)
    'tools': [for (final tool in request.tools) _tool(tool)],
  'temperature': ?request.options.temperature,
  'max_completion_tokens': ?request.options.maxOutputTokens,
  if (request.responseSchema case final schema?)
    'response_format': {
      'type': 'json_schema',
      'json_schema': {'name': 'response', 'schema': schema.toJson()},
    },
  'stream': true,
  'stream_options': {'include_usage': true},
};

List<Map<String, Object?>> _message(Message message) => switch (message.role) {
  Role.system => [
    {'role': 'system', 'content': message.text},
  ],
  Role.user => [
    {'role': 'user', 'content': message.text},
  ],
  Role.assistant => [_assistant(message)],
  Role.tool => [
    for (final result in message.parts.whereType<ToolResultPart>())
      {
        'role': 'tool',
        'tool_call_id': result.callId,
        'content': jsonEncode(result.output),
      },
  ],
};

Map<String, Object?> _assistant(Message message) => {
  'role': 'assistant',
  'content': message.text.isEmpty ? null : message.text,
  if (message.toolCalls.isNotEmpty)
    'tool_calls': [
      for (final call in message.toolCalls)
        {
          'id': call.id,
          'type': 'function',
          'function': {'name': call.name, 'arguments': _arguments(call)},
        },
    ],
};

String _arguments(ToolCallPart call) => switch (call.arguments) {
  final String raw => raw,
  final decoded => jsonEncode(decoded),
};

Map<String, Object?> _tool(ToolSpec tool) => {
  'type': 'function',
  'function': {
    'name': tool.name,
    'description': tool.description,
    'parameters': tool.input.toJson(),
  },
};
