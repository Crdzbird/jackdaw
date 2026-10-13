import 'package:jackdaw/jackdaw.dart';

/// Tools offered in every case.
const List<ToolSpec> benchTools = [
  ToolSpec(
    name: 'get_weather',
    description: 'Current weather for a city',
    input: ObjectSchema(
      properties: {
        'city': Schema.string(),
        'unit': Schema.string(enumValues: ['celsius', 'fahrenheit']),
      },
      required: ['city', 'unit'],
    ),
  ),
  ToolSpec(
    name: 'set_timer',
    description: 'Starts a countdown timer',
    input: ObjectSchema(
      properties: {'minutes': Schema.integer()},
      required: ['minutes'],
    ),
  ),
  ToolSpec(
    name: 'send_email',
    description: 'Sends an email',
    input: ObjectSchema(
      properties: {
        'to': Schema.string(),
        'subject': Schema.string(),
        'body': Schema.string(),
      },
      required: ['to', 'subject', 'body'],
    ),
  ),
  ToolSpec(
    name: 'find_contact',
    description: 'Looks up a contact by name',
    input: ObjectSchema(
      properties: {'name': Schema.string()},
      required: ['name'],
    ),
  ),
];
