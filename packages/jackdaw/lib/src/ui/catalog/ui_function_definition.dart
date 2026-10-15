import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_caller.dart';
import 'package:jackdaw/src/ui/catalog/ui_return_type.dart';

/// A function a catalog offers to bindings, checks and actions.
final class UiFunctionDefinition {
  /// Defines the function [name] taking [args] and returning [returns].
  ///
  /// [callers] limits which side may call it. A function that needs a
  /// user gesture, such as opening a link, sets [requiresUserActivation]
  /// and can only run from the renderer.
  const factory({
    required String name,
    required String description,
    required ObjectSchema args,
    required UiReturnType returns,
    UiCaller callers,
    bool requiresUserActivation,
  }) = UiFunctionDefinition._;

  const new _({
    required this.name,
    required this.description,
    required this.args,
    required this.returns,
    this.callers = UiCaller.rendererOnly,
    this.requiresUserActivation = false,
  });

  /// The name used in `{"@call": name}`.
  final String name;

  /// What the function does, shown to the model.
  final String description;

  /// The arguments, as properties of the `args` object.
  final ObjectSchema args;

  /// What the function returns.
  final UiReturnType returns;

  /// Which side may call the function.
  final UiCaller callers;

  /// Whether the function only runs in response to a user gesture.
  final bool requiresUserActivation;

  /// The function as an A2UI v1.0 catalog `functions` entry.
  Map<String, Object?> toJson() => {
    'type': 'object',
    'description': description,
    'returnType': returns.wire,
    if (callers != UiCaller.rendererOnly) 'allowedCallers': callers.name,
    if (requiresUserActivation) 'requiresUserActivation': true,
    'properties': {
      '@call': {'const': name},
      'args': args.toJson(),
    },
    'required': ['@call', 'args'],
  };
}
