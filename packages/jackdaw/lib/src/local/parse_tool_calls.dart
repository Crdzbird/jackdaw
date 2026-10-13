import 'dart:convert';

import 'package:jackdaw/src/message/part.dart';

final RegExp _block = RegExp(r'<tool_call>\s*([\s\S]*?)\s*</tool_call>');

/// The `<tool_call>` blocks in [text] as calls with ids starting with
/// [idPrefix]; `null` when a block is missing or not a call.
List<ToolCallPart>? parseToolCalls(String text, String idPrefix) {
  final calls = <ToolCallPart>[];
  for (final (index, match) in _block.allMatches(text).indexed) {
    final Object? json;
    try {
      json = jsonDecode(match.group(1)!);
    } on FormatException {
      return null;
    }
    if (json case {'name': final String name, 'arguments': final arguments}) {
      calls.add(
        ToolCallPart(id: '$idPrefix$index', name: name, arguments: arguments),
      );
    }
  }
  final complete =
      calls.isNotEmpty &&
      calls.length == _block.allMatches(text).length &&
      text.trimRight().endsWith('</tool_call>');
  return complete ? calls : null;
}
