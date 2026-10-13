import 'package:flutter/material.dart';

/// One message in a chat, aligned and coloured by who wrote it.
final class ChatBubble extends StatelessWidget {
  /// Shows [text], written by the user when [fromUser] is true. Text is
  /// selectable unless [selectable] is false, which is cheaper to lay out
  /// while an answer is still streaming.
  const factory({
    required String text,
    required bool fromUser,
    bool selectable,
    Key? key,
  }) = ChatBubble._;

  const new _({
    required this.text,
    required this.fromUser,
    this.selectable = true,
    super.key,
  });

  /// The message text.
  final String text;

  /// Whether the user wrote it.
  final bool fromUser;

  /// Whether the text can be selected and copied.
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = TextStyle(
      color: fromUser ? colors.onPrimaryContainer : colors.onSurfaceVariant,
    );
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Semantics(
          label: fromUser ? 'You said' : 'Assistant said',
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: fromUser
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: selectable
                ? SelectableText(text, style: style)
                : Text(text, style: style),
          ),
        ),
      ),
    );
  }
}
