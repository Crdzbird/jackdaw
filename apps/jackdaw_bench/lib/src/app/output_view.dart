import 'package:flutter/material.dart';

/// Scrollable, selectable view of the streamed answer.
class OutputView extends StatelessWidget {
  const new({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Expanded(
    child: SingleChildScrollView(
      child: SelectableText(
        text,
        style: const TextStyle(fontFamily: 'monospace', height: 1.4),
      ),
    ),
  );
}
