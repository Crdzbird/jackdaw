import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_function_definition.dart';
import 'package:jackdaw/src/ui/catalog/ui_return_type.dart';
import 'package:jackdaw/src/ui/catalog/ui_type.dart';

Schema _text(String description) =>
    UiType.dynamicString.ref(description: description);

Schema _number(String description) =>
    UiType.dynamicNumber.ref(description: description);

UiFunctionDefinition _format(
  String name,
  String description,
  Map<String, Schema> args,
  List<String> required,
) => UiFunctionDefinition(
  name: name,
  description: description,
  args: ObjectSchema(properties: args, required: required),
  returns: UiReturnType.string,
);

final Map<String, Schema> _digits = {
  'decimals': _number('Digits after the decimal point.'),
  'grouping': UiType.dynamicBoolean.ref(
    description: 'Whether to group thousands, true if unset.',
  ),
};

/// The basic catalog's functions that build text.
final List<UiFunctionDefinition> basicFormatFunctions = [
  _format(
    'formatString',
    r'Joins text and values. Each ${...} in the value is replaced: '
        r'${/a/b} by the data at that path, ${name} by the field of the '
        r'current list item, and ${fn(arg: value)} by a function result. '
        r'Write \${ for a literal ${.',
    {'value': _text('The text with placeholders.')},
    ['value'],
  ),
  _format(
    'formatNumber',
    'Writes a number with grouping and a fixed number of decimals.',
    {'value': _number('The number.'), ..._digits},
    ['value'],
  ),
  _format(
    'formatCurrency',
    'Writes an amount of money in a currency.',
    {
      'value': _number('The amount.'),
      'currency': _text('The ISO 4217 code, such as USD.'),
      ..._digits,
    },
    ['value', 'currency'],
  ),
  _format(
    'formatDate',
    'Writes a date with a Unicode pattern such as MMM d, yyyy or HH:mm.',
    {
      'value': UiType.dynamicValue.ref(description: 'An ISO 8601 date.'),
      'format': _text('The date pattern.'),
    },
    ['value', 'format'],
  ),
  _format(
    'pluralize',
    'Picks the text for the plural category of a count; other is required.',
    {
      'value': _number('The count.'),
      for (final category in ['zero', 'one', 'two', 'few', 'many', 'other'])
        category: _text('The text for the $category category.'),
    },
    ['value', 'other'],
  ),
];
