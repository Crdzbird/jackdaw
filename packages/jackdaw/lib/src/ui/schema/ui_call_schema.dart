import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_caller.dart';
import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/catalog/ui_return_type.dart';

/// The schema of a call to a renderer function of [catalog] that returns
/// one of [returns], as `{"@call": name, "args": {...}}`, or `null` when
/// the catalog has no such function.
///
/// [args] turns a function's argument schema into the schema the call
/// carries, so nested values can be resolved one call level deeper.
Schema? uiCallSchema(
  UiCatalog catalog,
  Set<UiReturnType> returns,
  ObjectSchema Function(ObjectSchema args) args,
) {
  final functions = [
    for (final function in catalog.functions)
      if (returns.contains(function.returns) &&
          function.callers != UiCaller.agentOnly)
        function,
  ];
  if (functions.isEmpty) return null;
  return UnionSchema(
    discriminator: '@call',
    variants: {
      for (final function in functions)
        function.name: ObjectSchema(
          properties: {'args': args(function.args)},
          required: ['args'],
          description: function.description,
        ),
    },
    description: 'A call to a catalog function.',
  );
}

/// The return types a value of each kind may come from.
const Map<String, Set<UiReturnType>> uiReturnsFor = {
  'string': {UiReturnType.string, UiReturnType.any},
  'number': {UiReturnType.number, UiReturnType.any},
  'boolean': {
    UiReturnType.boolean,
    UiReturnType.validationResult,
    UiReturnType.any,
  },
  'list': {UiReturnType.array, UiReturnType.any},
  'value': {
    UiReturnType.string,
    UiReturnType.number,
    UiReturnType.boolean,
    UiReturnType.array,
    UiReturnType.object,
    UiReturnType.validationResult,
    UiReturnType.any,
  },
  'action': {...UiReturnType.values},
};
