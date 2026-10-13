import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jackdaw_flutter/src/widgets/chat_bubble.dart';

/// The answer being generated. Only this widget rebuilds as text streams
/// in, inside its own repaint boundary.
final class StreamingBubble extends StatelessWidget {
  /// Shows [text] as it grows.
  const factory({required ValueListenable<String> text, Key? key}) =
      StreamingBubble._;

  const new _({required this.text, super.key});

  /// The growing answer.
  final ValueListenable<String> text;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ValueListenableBuilder<String>(
      valueListenable: text,
      builder: (context, value, _) => value.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : ChatBubble(text: value, fromUser: false, selectable: false),
    ),
  );
}
