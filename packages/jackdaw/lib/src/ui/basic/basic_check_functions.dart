import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_function_definition.dart';
import 'package:jackdaw/src/ui/catalog/ui_return_type.dart';
import 'package:jackdaw/src/ui/catalog/ui_type.dart';

UiFunctionDefinition _check(
  String name,
  String description,
  Map<String, Schema> args,
  List<String> required,
) => UiFunctionDefinition(
  name: name,
  description: description,
  args: ObjectSchema(properties: args, required: required),
  returns: UiReturnType.validationResult,
);

/// The basic catalog's validation functions, used in `checks`.
final List<UiFunctionDefinition> basicCheckFunctions = [
  _check(
    'required',
    'Passes when the value is not null, an empty string or an empty list.',
    {'value': UiType.dynamicValue.ref(description: 'The value to check.')},
    ['value'],
  ),
  _check(
    'regex',
    'Passes when the value matches the regular expression.',
    {
      'value': UiType.dynamicString.ref(description: 'The text to check.'),
      'pattern': const Schema.string(description: 'The regular expression.'),
    },
    ['value', 'pattern'],
  ),
  _check(
    'length',
    'Passes when the text length is within min and max; give at least one.',
    {
      'value': UiType.dynamicString.ref(description: 'The text to check.'),
      'min': const Schema.integer(description: 'The shortest length.'),
      'max': const Schema.integer(description: 'The longest length.'),
    },
    ['value'],
  ),
  _check(
    'numeric',
    'Passes when the number is within min and max; give at least one.',
    {
      'value': UiType.dynamicNumber.ref(description: 'The number to check.'),
      'min': const Schema.number(description: 'The lowest value.'),
      'max': const Schema.number(description: 'The highest value.'),
    },
    ['value'],
  ),
  _check(
    'email',
    'Passes when the text is an email address.',
    {'value': UiType.dynamicString.ref(description: 'The text to check.')},
    ['value'],
  ),
];
