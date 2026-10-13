import 'package:jackdaw/jackdaw.dart';

/// Builds a tool that counts how often it really ran.
Tool<Object?> countingTool(
  String name,
  List<int> runs, {
  bool idempotent = false,
  bool requiresApproval = false,
}) => Tool<Object?>(
  name: name,
  description: name,
  input: const ObjectSchema(properties: {}, additionalProperties: true),
  decode: (json) => json,
  run: (input) {
    runs[0]++;
    return {'ran': name, 'key': ToolContext.callId};
  },
  idempotent: idempotent,
  requiresApproval: requiresApproval,
);
