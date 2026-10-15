import 'package:jackdaw/src/ui/basic/basic_function_bodies.dart';
import 'package:jackdaw/src/ui/catalog/ui_caller.dart';
import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/eval/ui_eval_exception.dart';
import 'package:jackdaw/src/ui/eval/ui_function_body.dart';
import 'package:jackdaw/src/ui/eval/ui_host.dart';
import 'package:jackdaw/src/ui/eval/ui_scope.dart';
import 'package:jackdaw/src/ui/eval/ui_truth.dart';

/// Evaluates A2UI v1.0 dynamic values: literals, data bindings and calls
/// to the functions of a catalog.
///
/// A call runs only when the catalog lists the function for the renderer
/// and [functions] implements it; one that needs a user gesture runs only
/// in a scope started by one.
final class UiEvaluator {
  /// Creates an evaluator for [catalog], with [functions] implementing its
  /// functions and [host] deciding what links may open.
  factory(
    UiCatalog catalog, {
    Map<String, UiFunctionBody>? functions,
    UiHost host,
  }) = UiEvaluator._;

  new _(
    this.catalog, {
    Map<String, UiFunctionBody>? functions,
    this.host = const UiHost(),
  }) : functions = functions ?? basicFunctionBodies;

  /// The catalog whose functions may be called.
  final UiCatalog catalog;

  /// The implementations of the catalog's functions, by name.
  final Map<String, UiFunctionBody> functions;

  /// What the app lets generated UI do outside the surface.
  final UiHost host;

  /// The value of [value] in [scope]; throws a [UiEvalException] for a
  /// call that is not allowed or fails.
  Object? evaluate(Object? value, UiScope scope) => switch (value) {
    {'@path': final String path} => scope.read(path),
    {'@call': final String name} => _call(name, value['args'], scope),
    Map() => {
      for (final MapEntry(:key, :value) in value.entries)
        '$key'.startsWith('@@') ? '$key'.substring(1) : '$key': evaluate(
          value,
          scope,
        ),
    },
    List() => [for (final item in value) evaluate(item, scope)],
    _ => value,
  };

  /// [value] in [scope] as a boolean: true only for `true` or a passing
  /// validation result.
  bool truth(Object? value, UiScope scope) => uiTruth(evaluate(value, scope));

  Object? _call(String name, Object? args, UiScope scope) {
    final resolved = evaluate(args ?? const <String, Object?>{}, scope);
    if (resolved is! Map<String, Object?>) {
      throw UiEvalException(
        'EXPRESSION_ERROR',
        'The args of $name are not an object.',
      );
    }
    if (name == '@index') return _index(resolved, scope);
    final definition = catalog.function(name);
    final body = functions[name];
    if (definition == null ||
        body == null ||
        definition.callers == UiCaller.agentOnly) {
      throw UiEvalException('EXPRESSION_ERROR', 'There is no function $name.');
    }
    if (definition.requiresUserActivation && !scope.userActivation) {
      throw UiEvalException(
        'EXPRESSION_ERROR',
        '$name only runs on a user gesture.',
      );
    }
    return body(resolved, scope, host, (value) => evaluate(value, scope));
  }

  static num _index(Map<String, Object?> args, UiScope scope) {
    final index = scope.index;
    if (index == null) {
      throw const UiEvalException(
        'EXECUTION_ERROR',
        '@index is only known inside a list template.',
      );
    }
    return index +
        switch (args['offset']) {
          final num n => n,
          _ => 0,
        };
  }
}
