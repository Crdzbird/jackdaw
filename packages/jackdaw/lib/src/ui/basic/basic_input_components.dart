import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/basic/basic_props.dart';
import 'package:jackdaw/src/ui/catalog/ui_component_definition.dart';
import 'package:jackdaw/src/ui/catalog/ui_type.dart';

/// The basic catalog's button, text field and checkbox.
final List<UiComponentDefinition> basicInputComponents = [
  UiComponentDefinition(
    name: 'Button',
    description:
        'A button. Its child is usually a Text; use an Icon only for an '
        'icon button.',
    props: ObjectSchema(
      properties: {
        'child': child('The button content.'),
        'variant': choice('The button style.', [
          'default',
          'primary',
          'borderless',
        ]),
        'action': UiType.action.ref(description: 'What a press does.'),
        'checks': basicChecks,
        'weight': basicWeight,
      },
      required: ['child', 'action'],
    ),
  ),
  UiComponentDefinition(
    name: 'TextField',
    description: 'A text input, usually bound to the data model.',
    props: ObjectSchema(
      properties: {
        'label': text('The field label.'),
        'value': text('The text, usually a binding to the data model.'),
        'placeholder': text('Hint text shown while the field is empty.'),
        'variant': choice('The kind of input.', [
          'shortText',
          'longText',
          'number',
          'obscured',
        ]),
        'checks': basicChecks,
        'weight': basicWeight,
      },
      required: ['label'],
    ),
  ),
  UiComponentDefinition(
    name: 'CheckBox',
    description: 'A labeled checkbox.',
    props: ObjectSchema(
      properties: {
        'label': text('The checkbox label.'),
        'value': UiType.dynamicBoolean.ref(
          description: 'Whether it is checked, usually a binding.',
        ),
        'checks': basicChecks,
        'weight': basicWeight,
      },
      required: ['label', 'value'],
    ),
  ),
];
