import 'package:flutter/material.dart';
import 'package:jackdaw_flutter/src/widgets/bubble_frame.dart';
import 'package:jackdaw_flutter/src/widgets/paragraphs.dart';

/// One finished message in a chat. Text is selectable inside the
/// `SelectionArea` of `ChatMessageList`.
final class ChatBubble extends StatelessWidget {
  /// Shows [text], written by the user when [fromUser] is true.
  const factory({required String text, required bool fromUser, Key? key}) =
      ChatBubble._;

  const new _({required this.text, required this.fromUser, super.key});

  /// The message text.
  final String text;

  /// Whether the user wrote it.
  final bool fromUser;

  @override
  Widget build(BuildContext context) => BubbleFrame(
    fromUser: fromUser,
    label: fromUser ? 'You said' : 'Assistant said',
    child: Paragraphs(text),
  );
}
