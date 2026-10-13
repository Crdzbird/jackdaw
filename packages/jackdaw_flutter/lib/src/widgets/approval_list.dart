import 'package:flutter/material.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/controller/chat_controller.dart';
import 'package:jackdaw_flutter/src/controller/chat_listenables.dart';
import 'package:jackdaw_flutter/src/widgets/approval_card.dart';

/// Every tool call of a chat that waits for the user's decision.
final class ApprovalList extends StatelessWidget {
  /// Shows the pending approvals of [controller].
  const factory({required ChatController controller, Key? key}) =
      ApprovalList._;

  const new _({required this.controller, super.key});

  /// The chat whose approvals are shown.
  final ChatController controller;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<AgentApprovalRequested>>(
        valueListenable: controller.approvals,
        builder: (context, requests, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final request in requests)
              ApprovalCard(
                key: ValueKey(request.call.id),
                request: request,
                onApprove: () async {
                  await controller.decide(
                    request.call.id,
                    const ApprovalDecision.approve(),
                  );
                },
                onReject: () async {
                  await controller.decide(
                    request.call.id,
                    const ApprovalDecision.reject(),
                  );
                },
              ),
          ],
        ),
      );
}
