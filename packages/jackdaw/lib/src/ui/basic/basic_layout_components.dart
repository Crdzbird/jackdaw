import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/basic/basic_container.dart';
import 'package:jackdaw/src/ui/basic/basic_props.dart';
import 'package:jackdaw/src/ui/catalog/ui_component_definition.dart';

/// The basic catalog's components that arrange other components.
final List<UiComponentDefinition> basicLayoutComponents = [
  basicContainer('Row', 'Children side by side.'),
  basicContainer('Column', 'Children one above the other.'),
  UiComponentDefinition(
    name: 'List',
    description: 'A scrolling list of children.',
    props: ObjectSchema(
      properties: {
        'children': basicChildren,
        'direction': choice('The scroll direction.', [
          'vertical',
          'horizontal',
        ]),
        'align': choice('Placement across the scroll axis.', basicAlign),
        'weight': basicWeight,
      },
      required: ['children'],
    ),
  ),
  UiComponentDefinition(
    name: 'Card',
    description: 'A raised box around one child.',
    props: ObjectSchema(
      properties: {'child': child('The content.'), 'weight': basicWeight},
      required: ['child'],
    ),
  ),
  UiComponentDefinition(
    name: 'Tabs',
    description: 'Children shown one at a time behind titled tabs.',
    props: ObjectSchema(
      properties: {
        'tabs': Schema.array(
          items: ObjectSchema(
            properties: {
              'title': text('The tab title.'),
              'child': child('The tab content.'),
            },
            required: ['title', 'child'],
          ),
          description: 'The tabs, at least one.',
        ),
        'weight': basicWeight,
      },
      required: ['tabs'],
    ),
  ),
  UiComponentDefinition(
    name: 'Modal',
    description: 'A dialog that opens when its trigger is pressed.',
    props: ObjectSchema(
      properties: {
        'trigger': child('The component that opens the dialog.'),
        'content': child('The dialog content.'),
        'weight': basicWeight,
      },
      required: ['trigger', 'content'],
    ),
  ),
  UiComponentDefinition(
    name: 'Divider',
    description: 'A thin line between components.',
    props: ObjectSchema(
      properties: {
        'axis': choice('The line direction.', ['horizontal', 'vertical']),
        'weight': basicWeight,
      },
    ),
  ),
];
