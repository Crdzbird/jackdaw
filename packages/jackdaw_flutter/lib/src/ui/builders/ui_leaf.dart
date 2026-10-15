import 'package:flutter/widgets.dart';

/// [child] with the margin every visible component keeps around itself,
/// so nested rows and columns add no space of their own.
Widget uiLeaf(Widget child) =>
    Padding(padding: const EdgeInsets.all(8), child: child);
