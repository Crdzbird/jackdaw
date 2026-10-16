import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_dom/src/ui_dom_node.dart';

/// Reads a node's props in its scope and writes back where they are bound.
extension UiDomNodeValues on UiDomNode {
  /// The value of [prop], or `null` when it is unset or cannot be read.
  Object? value(String prop) => read(component.props[prop]);

  /// [value], with its bindings and calls read in this node's scope, or
  /// `null` when it cannot be read.
  Object? read(Object? value) {
    try {
      return controller.evaluator.evaluate(value, scope);
    } on UiEvalException {
      return null;
    }
  }

  /// [prop] as text, or an empty string when unset.
  String text(String prop) => switch (value(prop)) {
    null => '',
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

  /// Writes [value] where [prop] is bound, as an input does.
  void write(String prop, Object? value) {
    if (component.props[prop] case {'@path': final String path}) {
      controller.write(surface.id, resolveJsonPointer(path, scope.path), value);
    }
  }

  /// Runs this component's action, after a press.
  void trigger() => controller.trigger(surface.id, component, scope);

  /// The messages of this component's failing checks.
  List<String> get checkMessages =>
      uiCheckMessages(component, controller.evaluator, scope);
}
