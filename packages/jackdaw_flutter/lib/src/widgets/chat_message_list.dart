import 'package:flutter/material.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/controller/chat_controller.dart';
import 'package:jackdaw_flutter/src/controller/chat_listenables.dart';
import 'package:jackdaw_flutter/src/controller/chat_status.dart';
import 'package:jackdaw_flutter/src/widgets/chat_bubble.dart';
import 'package:jackdaw_flutter/src/widgets/streaming_bubble.dart';

/// The transcript, newest at the bottom, with the answer being generated
/// below it, all selectable. Tool messages and empty turns are not shown.
final class ChatMessageList extends StatelessWidget {
  /// Shows the messages of [controller].
  const factory({required ChatController controller, Key? key}) =
      ChatMessageList._;

  const new _({required this.controller, super.key});

  /// The chat to show.
  final ChatController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<List<Message>>(
    valueListenable: controller.messages,
    builder: (context, messages, _) {
      final shown = [
        for (final message in messages.reversed)
          if ((message.role == Role.user || message.role == Role.assistant) &&
              message.text.trim().isNotEmpty)
            message,
      ];
      return ValueListenableBuilder<ChatStatus>(
        valueListenable: controller.status,
        builder: (context, status, _) {
          final live = status == ChatStatus.responding ? 1 : 0;
          final answer = GlobalObjectKey(controller.state);
          return SelectionArea(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: shown.length + live,
              itemBuilder: (context, index) {
                if (index < live) {
                  return StreamingBubble(
                    text: controller.streaming,
                    contentKey: answer,
                  );
                }
                final message = shown[index - live];
                final latest = live == 0 && index == 0;
                return ChatBubble(
                  text: message.text,
                  fromUser: message.role == Role.user,
                  contentKey: latest && message.role == Role.assistant
                      ? answer
                      : null,
                );
              },
            ),
          );
        },
      );
    },
  );
}
