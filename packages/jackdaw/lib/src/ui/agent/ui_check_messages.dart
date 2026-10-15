import 'package:jackdaw/src/ui/eval/ui_eval_exception.dart';
import 'package:jackdaw/src/ui/eval/ui_evaluator.dart';
import 'package:jackdaw/src/ui/eval/ui_scope.dart';
import 'package:jackdaw/src/ui/eval/ui_truth.dart';
import 'package:jackdaw/src/ui/surface/ui_component.dart';

/// The messages of the checks of [component] that fail in [scope], in
/// order; a check that cannot be evaluated fails.
///
/// A failing check shows its own message, or failing that the message its
/// condition returned, or a generic one. A button with a failing check is
/// disabled.
List<String> uiCheckMessages(
  UiComponent component,
  UiEvaluator evaluator,
  UiScope scope,
) => [
  if (component.props['checks'] case final List<Object?> checks)
    for (final check in checks.whereType<Map<String, Object?>>())
      if (_failure(check, evaluator, scope) case final String message) message,
];

String? _failure(
  Map<String, Object?> check,
  UiEvaluator evaluator,
  UiScope scope,
) {
  Object? result;
  try {
    result = evaluator.evaluate(check['condition'], scope);
  } on UiEvalException {
    result = false;
  }
  if (uiTruth(result)) return null;
  return switch ((check['message'], result)) {
    (final String message, _) => message,
    (_, {'message': final String message}) => message,
    _ => 'This value is not valid.',
  };
}
