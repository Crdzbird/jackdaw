import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_component_definition.dart';
import 'package:jackdaw/src/ui/catalog/ui_type.dart';
import 'package:jackdaw/src/ui/schema/ui_schema_map.dart';
import 'package:jackdaw/src/ui/schema/ui_value_schemas.dart';

const Schema _child = RawSchema({'x-jackdaw-slot': 'child'});
const Schema _children = RawSchema({'x-jackdaw-slot': 'children'});

/// Whether [definition] has children, in a Child or ChildList prop.
bool uiNests(UiComponentDefinition definition) {
  var found = false;
  uiMapSchema(definition.props, (node) {
    if (UiType.of(node) case UiType.child || UiType.childList) found = true;
    return null;
  });
  return found;
}

/// [props] resolved at [callDepth], with each Child prop holding a [child]
/// component and each ChildList prop a list of them or a template.
ObjectSchema uiHolding(
  ObjectSchema props,
  UnionSchema child,
  UiValueSchemas values,
  int callDepth,
) {
  final slotted = uiMapSchema(
    props,
    (node) => switch (UiType.of(node)) {
      UiType.child => _child,
      UiType.childList => _children,
      _ => null,
    },
  );
  final list = AnyOfSchema([
    Schema.array(items: child, maxItems: 40),
    ObjectSchema(
      properties: {
        'template': child,
        'path': const Schema.string(description: 'The list it repeats over.'),
      },
      required: ['template', 'path'],
    ),
  ]);
  return uiMapSchema(
    values.resolve(slotted, callDepth),
    (node) => identical(node, _child)
        ? child
        : identical(node, _children)
        ? list
        : null,
  ) as ObjectSchema;
}
