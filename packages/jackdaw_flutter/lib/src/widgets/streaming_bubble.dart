import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jackdaw_flutter/src/widgets/bubble_frame.dart';
import 'package:jackdaw_flutter/src/widgets/paragraphs.dart';

/// The answer being generated. Only this widget rebuilds as text streams
/// in, inside its own repaint boundary.
///
/// The text is split into paragraphs, so finished paragraphs keep their
/// layout and only the last one is laid out again as it grows. Screen
/// readers hear that the assistant is answering, not every token; the full
/// text is announced once the answer is a message.
final class StreamingBubble extends StatelessWidget {
  /// Shows [text] as it grows. Give the finished message the same
  /// [contentKey] to keep the text's layout when the answer completes.
  const factory({
    required ValueListenable<String> text,
    Key? contentKey,
    Key? key,
  }) = StreamingBubble._;

  const new _({required this.text, this.contentKey, super.key});

  /// The growing answer.
  final ValueListenable<String> text;

  /// Key of the text, shared with the finished message.
  final Key? contentKey;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ValueListenableBuilder<String>(
      valueListenable: text,
      builder: (context, value, _) => BubbleFrame(
        fromUser: false,
        label: 'Assistant is answering',
        child: ExcludeSemantics(
          child: value.isEmpty
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Paragraphs(value, key: contentKey),
        ),
      ),
    ),
  );
}
