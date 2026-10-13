import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jackdaw/jackdaw.dart';

/// Asks the user to approve or reject one tool call, showing the exact
/// arguments that will run.
final class ApprovalCard extends StatelessWidget {
  /// Shows [request] with approve and reject actions.
  const factory({
    required AgentApprovalRequested request,
    required VoidCallback onApprove,
    required VoidCallback onReject,
    Key? key,
  }) = ApprovalCard._;

  const new _({
    required this.request,
    required this.onApprove,
    required this.onReject,
    super.key,
  });

  /// The call waiting for a decision.
  final AgentApprovalRequested request;

  /// Called when the user approves.
  final VoidCallback onApprove;

  /// Called when the user rejects.
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final arguments = const JsonEncoder.withIndent('  ')
        .convert(request.call.arguments);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Run ${request.call.name}?', style: text.titleSmall),
            Text(request.reason, style: text.bodySmall),
            const SizedBox(height: 8),
            SelectableText(arguments, style: text.bodySmall),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onReject, child: const Text('Reject')),
                FilledButton(
                  onPressed: onApprove,
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
