import 'package:flutter/material.dart';

/// The shape of a chat bubble, aligned and coloured by who wrote it, with
/// [label] for screen readers.
final class BubbleFrame extends StatelessWidget {
  /// Frames [child] as a message of the user when [fromUser] is true.
  const factory({
    required bool fromUser,
    required String label,
    required Widget child,
    Key? key,
  }) = BubbleFrame._;

  const new _({
    required this.fromUser,
    required this.label,
    required this.child,
    super.key,
  });

  /// Whether the user wrote the message.
  final bool fromUser;

  /// What screen readers announce for the bubble.
  final String label;

  /// The content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Semantics(
          label: label,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: fromUser
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: fromUser
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
