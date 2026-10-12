import 'dart:convert';

import 'package:jackdaw/jackdaw.dart';

/// Builds the JSON body of a streaming `/api/chat` request.
///
/// [numCtx], [topK] and [keepAlive] are Ollama settings that the
/// OpenAI-compatible endpoint cannot express.
Map<String, Object?> encodeChatRequest(
  String model,
  ModelRequest request, {
  int? numCtx,
  int? topK,
  String? keepAlive,
}) {
  final options = {
    'temperature': ?request.options.temperature,
    'num_predict': ?request.options.maxOutputTokens,
    'num_ctx': ?numCtx,
    'top_k': ?topK,
  };
  return {
    'model': model,
    'stream': true,
    'messages': [for (final m in request.messages) ..._message(m)],
    if (request.tools.isNotEmpty)
      'tools': [for (final tool in request.tools) _tool(tool)],
    if (request.responseSchema case final schema?) 'format': schema.toJson(),
    if (options.isNotEmpty) 'options': options,
    'keep_alive': ?keepAlive,
  };
}

List<Map<String, Object?>> _message(Message message) => switch (message.role) {
  Role.tool => [
    for (final result in message.parts.whereType<ToolResultPart>())
      {
        'role': 'tool',
        'tool_name': result.name,
        'content': result.output is String
            ? result.output
            : jsonEncode(result.output),
      },
  ],
  Role.assistant => [
    {
      'role': 'assistant',
      'content': message.text,
      if (message.toolCalls.isNotEmpty)
        'tool_calls': [
          for (final call in message.toolCalls)
            {
              'id': call.id,
              'function': {
                'name': call.name,
                'arguments': call.arguments is Map
                    ? call.arguments
                    : <String, Object?>{},
              },
            },
        ],
    },
  ],
  Role.system || Role.user => [
    {'role': message.role.name, 'content': message.text},
  ],
};

Map<String, Object?> _tool(ToolSpec tool) => {
  'type': 'function',
  'function': {
    'name': tool.name,
    'description': tool.description,
    'parameters': tool.input.toJson(),
  },
};
