import 'dart:convert';

import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/tool/tool_spec.dart';

/// Opens a tool call in the output of a local model.
const String toolCallOpen = '<tool_call>\n';

/// Closes a tool call in the output of a local model.
const String toolCallClose = '\n</tool_call>';

/// [call] written the way a local model is asked to write it.
String toolCallBlock(ToolCallPart call) {
  final json = jsonEncode({'name': call.name, 'arguments': call.arguments});
  return '$toolCallOpen$json$toolCallClose';
}

/// [result] written the way a local model reads it back.
String toolResponseBlock(ToolResultPart result) =>
    '<tool_response>\n'
    '${jsonEncode({'name': result.name, 'content': result.output})}'
    '\n</tool_response>';

/// The system prompt section that offers [tools] to a local model.
///
/// It follows the Hermes convention that many open models, Qwen among
/// them, were trained on; the grammar enforces it whatever the model.
String toolInstructions(List<ToolSpec> tools) {
  final signatures = [
    for (final tool in tools)
      jsonEncode({
        'type': 'function',
        'function': {
          'name': tool.name,
          'description': tool.description,
          'parameters': tool.input.toJson(),
        },
      }),
  ].join('\n');
  return '# Tools\n\n'
      'You may call one or more functions to assist with the user query.\n\n'
      'You are provided with function signatures within <tools></tools> '
      'XML tags:\n<tools>\n$signatures\n</tools>\n\n'
      'For each function call, return a json object with function name and '
      'arguments within <tool_call></tool_call> XML tags:\n'
      '<tool_call>\n{"name": <function-name>, "arguments": '
      '<args-json-object>}\n</tool_call>\n\n'
      'Results come back within <tool_response></tool_response> XML tags.\n\n'
      'Call a function only when the user asks for something it does. '
      'Answer all other questions yourself, from your own knowledge, without '
      'calling a function.';
}
