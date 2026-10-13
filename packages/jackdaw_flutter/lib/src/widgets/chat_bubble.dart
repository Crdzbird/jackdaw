import 'package:flutter/material.dart';
import 'package:jackdaw_flutter/src/widgets/bubble_frame.dart';
import 'package:jackdaw_flutter/src/widgets/paragraphs.dart';

/// One finished message in a chat. Text is selectable inside the
/// `SelectionArea` of `ChatMessageList`.
final class ChatBubble extends StatelessWidget {
  /// Shows [text], written by the user when [fromUser] is true.
  /// [contentKey] lets the text reuse the layout of a streaming bubble.
  const factory({
    required String text,
    required bool fromUser,
    Key? contentKey,
    Key? key,
  }) = ChatBubble._;

  const new _({
    required this.text,
    required this.fromUser,
    this.contentKey,
    super.key,
  });

  /// The message text.
  final String text;

  /// Whether the user wrote it.
  final bool fromUser;

  /// Key of the text, shared with the streaming bubble of the same answer.
  final Key? contentKey;

  @override
  Widget build(BuildContext context) => BubbleFrame(
    fromUser: fromUser,
    label: fromUser ? 'You said' : 'Assistant said',
    child: Paragraphs(text, key: contentKey),
  );
}
