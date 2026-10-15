import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/basic/basic_props.dart';
import 'package:jackdaw/src/ui/catalog/ui_component_definition.dart';
import 'package:jackdaw/src/ui/catalog/ui_type.dart';

/// The basic catalog's choice picker, slider and date and time input.
final List<UiComponentDefinition> basicPickerComponents = [
  UiComponentDefinition(
    name: 'ChoicePicker',
    description: 'A choice of one or several options.',
    props: ObjectSchema(
      properties: {
        'label': text('The picker label.'),
        'variant': choice('Whether one or several options may be chosen.', [
          'mutuallyExclusive',
          'multipleSelection',
        ]),
        'options': Schema.array(
          items: ObjectSchema(
            properties: {
              'label': text('The option label.'),
              'value': const Schema.string(description: 'The option value.'),
            },
            required: ['label', 'value'],
          ),
          description: 'The options.',
        ),
        'value': UiType.dynamicStringList.ref(
          description: 'The chosen values, usually a binding.',
        ),
        'displayStyle': choice('How options are drawn.', ['checkbox', 'chips']),
        'filterable': const Schema.boolean(
          description: 'Whether a search field filters the options.',
        ),
        'checks': basicChecks,
        'weight': basicWeight,
      },
      required: ['options', 'value'],
    ),
  ),
  UiComponentDefinition(
    name: 'Slider',
    description: 'A slider for a number in a range.',
    props: ObjectSchema(
      properties: {
        'label': text('The slider label.'),
        'min': const Schema.number(
          description: 'The lowest value, 0 if unset.',
        ),
        'max': const Schema.number(description: 'The highest value.'),
        'value': UiType.dynamicNumber.ref(
          description: 'The value, usually a binding.',
        ),
        'steps': const Schema.integer(
          description: 'Number of steps the range snaps to, at least 1.',
        ),
        'checks': basicChecks,
        'weight': basicWeight,
      },
      required: ['max', 'value'],
    ),
  ),
  UiComponentDefinition(
    name: 'DateTimeInput',
    description: 'A date input, a time input or both.',
    props: ObjectSchema(
      properties: {
        'label': text('The input label.'),
        'value': text('The ISO 8601 value, usually a binding.'),
        'enableDate': const Schema.boolean(
          description: 'Whether to pick a date.',
        ),
        'enableTime': const Schema.boolean(
          description: 'Whether to pick a time.',
        ),
        'min': text('The earliest allowed ISO 8601 value.'),
        'max': text('The latest allowed ISO 8601 value.'),
        'checks': basicChecks,
        'weight': basicWeight,
      },
      required: ['value'],
    ),
  ),
];
