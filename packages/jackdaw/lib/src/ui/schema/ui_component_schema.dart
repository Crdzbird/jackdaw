import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_component_definition.dart';

const Schema _id = Schema.string(description: 'A unique id; root for the top.');

const Schema _rootId = Schema.string(enumValues: ['root']);

/// The schema of one instance of [definition], whose resolved props are
/// [props]: its id, its props and its [accessibility] attributes. A [root]
/// component must have the id `root`.
ObjectSchema uiComponentSchema(
  UiComponentDefinition definition,
  ObjectSchema props,
  ObjectSchema accessibility, {
  bool root = false,
}) => ObjectSchema(
  properties: {
    'id': root ? _rootId : _id,
    ...props.properties,
    'accessibility': accessibility,
  },
  required: ['id', ...props.required],
  description: definition.description,
);
