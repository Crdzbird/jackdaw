import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/ui/ui_node.dart';

/// Reads a node's props in its scope and writes back where they are bound.
extension UiNodeValues on UiNode {
  /// The value of [prop], or `null` when it is unset or cannot be
  /// evaluated.
  Object? value(String prop) {
    try {
      return controller.evaluator.evaluate(component.props[prop], scope);
    } on UiEvalException {
      return null;
    }
  }

  /// [prop] as text, or `null` when unset.
  String? text(String prop) => switch (value(prop)) {
    null => null,
    final value => uiText(value),
  };

  /// [prop] as a number, or `null`.
  double? number(String prop) => switch (value(prop)) {
    final num n => n.toDouble(),
    final String s => double.tryParse(s),
    _ => null,
  };

  /// Whether [prop] is true.
  bool truth(String prop) => uiTruth(value(prop));

  /// The data model pointer [prop] is bound to, or `null` for a literal.
  String? pointer(String prop) => switch (component.props[prop]) {
    {'@path': final String path} => resolveJsonPointer(path, scope.path),
    _ => null,
  };

  /// Writes [value] where [prop] is bound, as an input does.
  void write(String prop, Object? value) {
    if (pointer(prop) case final at?) controller.write(surface.id, at, value);
  }

  /// The messages of this component's failing checks.
  List<String> get checkMessages =>
      uiCheckMessages(component, controller.evaluator, scope);
}
