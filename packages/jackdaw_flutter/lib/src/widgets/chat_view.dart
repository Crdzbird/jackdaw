import 'package:flutter/material.dart';
import 'package:jackdaw_flutter/src/controller/chat_controller.dart';
import 'package:jackdaw_flutter/src/controller/chat_listenables.dart';
import 'package:jackdaw_flutter/src/controller/chat_status.dart';
import 'package:jackdaw_flutter/src/widgets/approval_list.dart';
import 'package:jackdaw_flutter/src/widgets/chat_composer.dart';
import 'package:jackdaw_flutter/src/widgets/chat_message_list.dart';

/// A complete chat: transcript, streamed answer, pending approvals, the
/// last error and a composer.
final class ChatView extends StatelessWidget {
  /// Shows and drives [controller].
  const factory({required ChatController controller, String hint, Key? key}) =
      ChatView._;

  const new _({required this.controller, this.hint = 'Message', super.key});

  /// The chat to show.
  final ChatController controller;

  /// Placeholder text of the empty composer.
  final String hint;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(child: ChatMessageList(controller: controller)),
      ApprovalList(controller: controller),
      ValueListenableBuilder<ChatStatus>(
        valueListenable: controller.status,
        builder: (context, status, _) => status == ChatStatus.failed
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Something went wrong: ${controller.state.error}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
            : const SizedBox.shrink(),
      ),
      ChatComposer(controller: controller, hint: hint),
    ],
  );
}
