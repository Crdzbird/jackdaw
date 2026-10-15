import 'package:flutter/widgets.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/ui/ui_node.dart';

/// [widget] with the accessibility attributes of [node]: hidden ones are
/// left out of the semantics tree, and a label and live region are added.
Widget uiSemantics(UiNode node, Widget widget) {
  final attributes = node.component.props['accessibility'];
  if (attributes is! Map<String, Object?>) return widget;
  final evaluator = node.controller.evaluator;
  Object? read(String key) {
    try {
      return evaluator.evaluate(attributes[key], node.scope);
    } on UiEvalException {
      return null;
    }
  }

  if (uiTruth(read('hidden'))) return ExcludeSemantics(child: widget);
  final label = read('label');
  return Semantics(
    label: label == null ? null : uiText(label),
    liveRegion:
        attributes['live'] == 'polite' || attributes['live'] == 'assertive',
    child: widget,
  );
}
