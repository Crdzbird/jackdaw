import 'package:flutter/material.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_leaf.dart';
import 'package:jackdaw_flutter/src/ui/ui_node.dart';
import 'package:jackdaw_flutter/src/ui/ui_node_values.dart';

/// A Text component: a caption or body text from the theme.
Widget uiTextWidget(UiNode node) => Builder(
  builder: (context) {
    final theme = Theme.of(context).textTheme;
    return uiLeaf(
      Text(
        node.text('text') ?? '',
        style: node.component.props['variant'] == 'caption'
            ? theme.bodySmall
            : theme.bodyMedium,
      ),
    );
  },
);

/// A Divider component, across or along its parent.
Widget uiDividerWidget(UiNode node) =>
    node.component.props['axis'] == 'vertical'
    ? const SizedBox(height: 24, child: VerticalDivider())
    : const Divider();

/// A Card component: an outlined box around its child.
Widget uiCardWidget(UiNode node) => Builder(
  builder: (context) => uiLeaf(
    DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: node.child('child'),
      ),
    ),
  ),
);
