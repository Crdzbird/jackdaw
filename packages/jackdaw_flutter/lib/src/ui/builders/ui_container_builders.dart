import 'package:flutter/material.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_leaf.dart';
import 'package:jackdaw_flutter/src/ui/ui_node.dart';

/// A Tabs component: titled tabs that show one child at a time.
Widget uiTabsWidget(UiNode node) {
  final tabs = [
    for (final tab in switch (node.component.props['tabs']) {
      final List<Object?> list => list.whereType<Map<String, Object?>>(),
      _ => const <Map<String, Object?>>[],
    })
      (
        uiText(_value(node, tab['title'])),
        node.node(tab['child'] is String ? tab['child']! as String : null),
      ),
  ];
  if (tabs.isEmpty) return const SizedBox.shrink();
  return DefaultTabController(
    length: tabs.length,
    child: Builder(
      builder: (context) {
        final controller = DefaultTabController.of(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              isScrollable: true,
              tabs: [for (final (title, _) in tabs) Tab(text: title)],
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (_, _) =>
                  tabs[controller.index].$2?.build() ?? const SizedBox.shrink(),
            ),
          ],
        );
      },
    ),
  );
}

/// A Modal component: its trigger opens a dialog with its content.
Widget uiModalWidget(UiNode node) => Builder(
  builder: (context) => InkWell(
    onTap: () => showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ListenableBuilder(
          listenable: node.controller,
          builder: (_, _) => uiLeaf(node.child('content')),
        ),
      ),
    ),
    child: AbsorbPointer(child: node.child('trigger')),
  ),
);

Object? _value(UiNode node, Object? value) {
  try {
    return node.controller.evaluator.evaluate(value, node.scope);
  } on UiEvalException {
    return null;
  }
}
