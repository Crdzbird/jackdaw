import 'package:flutter/material.dart';
import 'package:jackdaw_flutter/src/ui/ui_node.dart';
import 'package:jackdaw_flutter/src/ui/ui_node_values.dart';

MainAxisAlignment _justify(Object? value) => switch (value) {
  'center' => MainAxisAlignment.center,
  'end' => MainAxisAlignment.end,
  'spaceBetween' => MainAxisAlignment.spaceBetween,
  'spaceAround' => MainAxisAlignment.spaceAround,
  'spaceEvenly' => MainAxisAlignment.spaceEvenly,
  _ => MainAxisAlignment.start,
};

CrossAxisAlignment _align(Object? value, {required bool stretchable}) =>
    switch (value) {
      'start' => CrossAxisAlignment.start,
      'center' => CrossAxisAlignment.center,
      'end' => CrossAxisAlignment.end,
      'stretch' when stretchable => CrossAxisAlignment.stretch,
      _ => CrossAxisAlignment.start,
    };

/// A Row component: children side by side, each taking its weight of the
/// width, or as little as it needs. Weights and stretching apply only
/// where the row's size is bounded, so it never asks for infinite space.
Widget uiRowWidget(UiNode node) => LayoutBuilder(
  builder: (context, constraints) => Row(
    mainAxisAlignment: _justify(node.component.props['justify']),
    crossAxisAlignment: _align(
      node.component.props['align'] ?? 'center',
      stretchable: constraints.hasBoundedHeight,
    ),
    children: [
      for (final child in node.nodes('children'))
        if (constraints.hasBoundedWidth)
          Flexible(
            flex: (child.number('weight') ?? 1).round().clamp(1, 1000),
            fit: child.number('weight') == null ? FlexFit.loose : FlexFit.tight,
            child: child.build(),
          ),
      if (!constraints.hasBoundedWidth)
        for (final child in node.nodes('children')) child.build(),
    ],
  ),
);

/// A Column component: children one above the other, stretched across
/// unless told otherwise or the width is unbounded.
Widget uiColumnWidget(UiNode node) => _column(node, 'justify');

/// A List component: a column, or a row that scrolls sideways.
Widget uiListWidget(UiNode node) {
  if (node.component.props['direction'] != 'horizontal') {
    return _column(node, null);
  }
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [for (final child in node.nodes('children')) child.build()],
    ),
  );
}

Widget _column(UiNode node, String? justify) {
  final align = node.component.props['align'] ?? 'stretch';
  return Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: _justify(
      justify == null ? null : node.component.props[justify],
    ),
    crossAxisAlignment: _align(align, stretchable: false),
    children: [
      for (final child in node.nodes('children'))
        if (align == 'stretch') child.build(stretch: true),
      if (align != 'stretch')
        for (final child in node.nodes('children')) child.build(),
    ],
  );
}
