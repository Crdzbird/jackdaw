import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_function_definition.dart';
import 'package:jackdaw/src/ui/catalog/ui_return_type.dart';
import 'package:jackdaw/src/ui/catalog/ui_type.dart';

final Schema _conditions = Schema.array(
  items: UiType.dynamicBoolean.ref(),
  description: 'Two or more conditions.',
);

/// The basic catalog's link and logic functions.
final List<UiFunctionDefinition> basicLogicFunctions = [
  UiFunctionDefinition(
    name: 'openUrl',
    description: 'Opens a link. Only runs when the user presses something.',
    args: ObjectSchema(
      properties: {'url': UiType.dynamicString.ref(description: 'The URL.')},
      required: ['url'],
    ),
    returns: UiReturnType.none,
    requiresUserActivation: true,
  ),
  UiFunctionDefinition(
    name: 'and',
    description: 'True when every condition is true.',
    args: ObjectSchema(
      properties: {'values': _conditions},
      required: ['values'],
    ),
    returns: UiReturnType.boolean,
  ),
  UiFunctionDefinition(
    name: 'or',
    description: 'True when any condition is true.',
    args: ObjectSchema(
      properties: {'values': _conditions},
      required: ['values'],
    ),
    returns: UiReturnType.boolean,
  ),
  UiFunctionDefinition(
    name: 'not',
    description: 'True when the condition is false.',
    args: ObjectSchema(
      properties: {
        'value': UiType.dynamicBoolean.ref(description: 'The condition.'),
      },
      required: ['value'],
    ),
    returns: UiReturnType.boolean,
  ),
];
