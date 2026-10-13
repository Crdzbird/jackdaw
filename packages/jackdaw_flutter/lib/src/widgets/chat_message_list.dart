import 'package:flutter/material.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/controller/chat_controller.dart';
import 'package:jackdaw_flutter/src/controller/chat_listenables.dart';
import 'package:jackdaw_flutter/src/controller/chat_status.dart';
import 'package:jackdaw_flutter/src/widgets/chat_bubble.dart';
import 'package:jackdaw_flutter/src/widgets/streaming_bubble.dart';

const ValueKey<String> _streaming = ValueKey('streaming');

/// The transcript, newest at the bottom, with the answer being generated
/// below it, all selectable. Tool messages and empty turns are not shown.
/// Each bubble is keyed by its place in the transcript, so a new message or
/// the streaming bubble does not rebuild or lay out the ones already shown.
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
        for (final (index, message) in messages.indexed.toList().reversed)
          if ((message.role == Role.user || message.role == Role.assistant) &&
              message.text.trim().isNotEmpty)
            (index, message),
      ];
      final position = {
        for (final (at, (index, _)) in shown.indexed) index: at,
      };
      return ValueListenableBuilder<ChatStatus>(
        valueListenable: controller.status,
        builder: (context, status, _) {
          final live = status == ChatStatus.responding ? 1 : 0;
          return SelectionArea(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: shown.length + live,
              findChildIndexCallback: (key) => switch (key) {
                ValueKey<int>(:final value) when position[value] != null =>
                  position[value]! + live,
                _ when key == _streaming && live == 1 => 0,
                _ => null,
              },
              itemBuilder: (context, index) {
                if (index < live) {
                  return StreamingBubble(
                    key: _streaming,
                    text: controller.streaming,
                    contentKey: controller.state.layoutKey(messages.length),
                  );
                }
                final (order, message) = shown[index - live];
                return ChatBubble(
                  key: ValueKey<int>(order),
                  text: message.text,
                  fromUser: message.role == Role.user,
                  contentKey: message.role == Role.assistant
                      ? controller.state.layoutKey(order)
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
