import 'package:flutter/material.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/controller/chat_controller.dart';
import 'package:jackdaw_flutter/src/controller/chat_listenables.dart';
import 'package:jackdaw_flutter/src/controller/chat_status.dart';
import 'package:jackdaw_flutter/src/ui/ui_surface_view.dart';
import 'package:jackdaw_flutter/src/widgets/bubble_frame.dart';
import 'package:jackdaw_flutter/src/widgets/chat_bubble.dart';
import 'package:jackdaw_flutter/src/widgets/chat_entries.dart';
import 'package:jackdaw_flutter/src/widgets/streaming_bubble.dart';

const ValueKey<String> _streaming = ValueKey('streaming');

/// The transcript, newest at the bottom, with the answer being generated
/// below it, all selectable. Tool messages and empty turns are not shown,
/// except where a tool showed UI, which appears at the last place it was
/// shown.
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
      final shown = chatEntries(messages, controller.ui);
      final position = {
        for (final (at, entry) in shown.indexed) entry.index: at,
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
                final entry = shown[index - live];
                final ui = controller.ui;
                if (entry.surfaces.isNotEmpty && ui != null) {
                  return BubbleFrame(
                    key: ValueKey<int>(entry.index),
                    fromUser: false,
                    label: 'Assistant showed',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final id in entry.surfaces)
                          UiSurfaceView(controller: ui, surfaceId: id),
                      ],
                    ),
                  );
                }
                return ChatBubble(
                  key: ValueKey<int>(entry.index),
                  text: entry.text,
                  fromUser: entry.message.role == Role.user,
                  contentKey: entry.message.role == Role.assistant
                      ? controller.state.layoutKey(entry.index)
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
