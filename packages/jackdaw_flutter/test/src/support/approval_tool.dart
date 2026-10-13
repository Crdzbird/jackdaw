import 'package:jackdaw/jackdaw.dart';

/// A tool that records how often it ran and needs approval.
Tool<Object?> approvalTool(List<int> runs) => Tool<Object?>(
  name: 'send_email',
  description: 'Sends an email',
  input: const ObjectSchema(properties: {}, additionalProperties: true),
  decode: (json) => json,
  run: (_) {
    runs[0]++;
    return {'sent': true};
  },
  requiresApproval: true,
);
