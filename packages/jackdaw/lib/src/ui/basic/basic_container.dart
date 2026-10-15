import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/basic/basic_props.dart';
import 'package:jackdaw/src/ui/catalog/ui_component_definition.dart';

const List<String> _justify = [
  'start',
  'center',
  'end',
  'spaceBetween',
  'spaceAround',
  'spaceEvenly',
  'stretch',
];

/// Placements across a container's main axis.
const List<String> basicAlign = ['start', 'center', 'end', 'stretch'];

/// A row or column named [name].
UiComponentDefinition basicContainer(String name, String description) =>
    UiComponentDefinition(
      name: name,
      description: description,
      props: ObjectSchema(
        properties: {
          'children': basicChildren,
          'justify': choice('Placement along the main axis.', _justify),
          'align': choice('Placement across the main axis.', basicAlign),
          'weight': basicWeight,
        },
        required: ['children'],
      ),
    );
