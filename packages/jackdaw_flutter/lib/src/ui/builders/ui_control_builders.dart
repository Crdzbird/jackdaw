import 'package:flutter/material.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_leaf.dart';
import 'package:jackdaw_flutter/src/ui/ui_node.dart';
import 'package:jackdaw_flutter/src/ui/ui_node_values.dart';

/// A Button component, disabled while one of its checks fails.
Widget uiButtonWidget(UiNode node) {
  final onPressed = node.checkMessages.isEmpty ? node.trigger : null;
  final child = node.child('child');
  return uiLeaf(switch (node.component.props['variant']) {
    'primary' => FilledButton(onPressed: onPressed, child: child),
    'borderless' => TextButton(onPressed: onPressed, child: child),
    _ => OutlinedButton(onPressed: onPressed, child: child),
  });
}

/// A CheckBox component bound to the data model, with the message of its
/// first failing check.
Widget uiCheckBoxWidget(UiNode node) => Builder(
  builder: (context) {
    final messages = node.checkMessages;
    return uiLeaf(
      CheckboxListTile(
        value: node.truth('value'),
        onChanged: (checked) => node.write('value', checked ?? false),
        title: Text(node.text('label') ?? ''),
        subtitle: messages.isEmpty
            ? null
            : Text(
                messages.first,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  },
);
