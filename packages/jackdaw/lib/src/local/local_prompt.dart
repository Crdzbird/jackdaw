import 'dart:convert';

import 'package:jackdaw/src/local/tool_call_format.dart';
import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/message/role.dart';
import 'package:jackdaw/src/model/model_request.dart';
import 'package:jackdaw/src/schema/schema.dart';

/// [request] as role and content pairs for a local model's chat template.
///
/// Tools and the response schema are described in the system message,
/// assistant tool calls are written as `<tool_call>` blocks and tool
/// results come back as a user message of `<tool_response>` blocks, so the
/// model sees the whole exchange in the format it is asked to use.
List<(String, String)> localPrompt(ModelRequest request) {
  final notes = [
    if (request.tools.isNotEmpty) toolInstructions(request.tools),
    if (request.responseSchema case final schema?) _schemaNote(schema),
  ];
  final pairs = [for (final m in request.messages) _pair(m)];
  if (notes.isEmpty) return pairs;
  final extra = notes.join('\n\n');
  if (pairs case [('system', final system), ...final rest]) {
    return [('system', '$system\n\n$extra'), ...rest];
  }
  return [('system', extra), ...pairs];
}

(String, String) _pair(Message message) => switch (message.role) {
  Role.assistant => (
    'assistant',
    [
      if (message.text.isNotEmpty) message.text,
      for (final call in message.parts.whereType<ToolCallPart>())
        toolCallBlock(call),
    ].join('\n'),
  ),
  Role.tool => (
    'user',
    [
      for (final result in message.parts.whereType<ToolResultPart>())
        toolResponseBlock(result),
    ].join('\n'),
  ),
  _ => (message.role.name, message.text),
};

String _schemaNote(Schema schema) =>
    'Reply with JSON only, matching this JSON Schema: '
    '${jsonEncode(schema.toJson())}';
