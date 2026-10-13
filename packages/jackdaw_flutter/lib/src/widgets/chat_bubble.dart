import 'package:flutter/material.dart';

/// One message in a chat, aligned and coloured by who wrote it.
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
            child: SelectableText(
              text,
              style: TextStyle(
                color: fromUser
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
