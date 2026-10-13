import 'package:flutter/widgets.dart';

/// [text] as one [Text] per paragraph, so a paragraph that did not change
/// keeps its layout when the text grows.
final class Paragraphs extends StatelessWidget {
  /// Shows [text], split at blank lines.
  const factory(String text, {Key? key}) = Paragraphs._;

  const new _(this.text, {super.key});

  /// The text to show.
  final String text;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: [
      for (final paragraph in text.split('\n\n'))
        if (paragraph.isNotEmpty) Text(paragraph),
    ],
  );
}
