import 'dart:convert';

import 'package:jackdaw/jackdaw.dart';

/// Converts [messages] into role and content pairs for a chat template.
///
/// When [schema] is set, an instruction describing the expected JSON is
/// added to the system message. The grammar already enforces the shape;
/// the instruction tells the model what the fields mean.
List<(String, String)> templateMessages(
  List<Message> messages,
  Schema? schema,
) {
  final pairs = [for (final m in messages) (m.role.name, m.text)];
  if (schema == null) return pairs;
  final instruction =
      'Reply with JSON only, matching this JSON Schema: '
      '${jsonEncode(schema.toJson())}';
  if (pairs case [('system', final system), ...final rest]) {
    return [('system', '$system\n\n$instruction'), ...rest];
  }
  return [('system', instruction), ...pairs];
}
