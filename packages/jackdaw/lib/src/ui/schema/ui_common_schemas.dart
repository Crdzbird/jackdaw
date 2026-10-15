import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_type.dart';
import 'package:jackdaw/src/ui/schema/ui_value_schemas.dart';

/// A binding to the data model, written `{"@path": "/a/b"}`.
const ObjectSchema uiBinding = ObjectSchema(
  properties: {
    '@path': Schema.string(
      description: 'A JSON Pointer, absolute or relative to the list item.',
    ),
  },
  required: ['@path'],
  description: 'A value read from the data model.',
);

const Schema _id = Schema.string(description: 'A component id.');

/// The schema of the common [type] at [depth], with calls from [schemas].
Schema uiCommonSchema(UiType type, int depth, UiValueSchemas schemas) {
  Schema dynamic(Schema literal, String kind) =>
      AnyOfSchema([literal, uiBinding, ?schemas.call(kind, depth)]);
  return switch (type) {
    UiType.dynamicString => dynamic(const Schema.string(), 'string'),
    UiType.dynamicNumber => dynamic(const Schema.number(), 'number'),
    UiType.dynamicBoolean => dynamic(const Schema.boolean(), 'boolean'),
    UiType.dynamicStringList => dynamic(
      const Schema.array(items: Schema.string()),
      'list',
    ),
    UiType.dynamicValue => AnyOfSchema([
      const Schema.string(),
      const Schema.number(),
      const Schema.boolean(),
      const Schema.array(items: Schema.raw({})),
      uiBinding,
      ?schemas.call('value', depth),
    ]),
    UiType.dataBinding => uiBinding,
    UiType.child => _id,
    UiType.childList => const AnyOfSchema([
      Schema.array(items: _id, maxItems: 40),
      ObjectSchema(
        properties: {
          'componentId': Schema.string(
            description: 'The component repeated for each item.',
          ),
          'path': Schema.string(description: 'The list in the data model.'),
        },
        required: ['componentId', 'path'],
      ),
    ]),
    UiType.action => _action(depth, schemas),
    UiType.functionCall =>
      schemas.call('action', depth) ??
          (throw StateError('the catalog has no functions to call')),
    UiType.checkRule => ObjectSchema(
      properties: {
        'condition': AnyOfSchema([uiBinding, ?schemas.call('boolean', depth)]),
        'message': const Schema.string(description: 'Shown when it fails.'),
      },
      required: ['condition'],
    ),
  };
}

Schema _action(int depth, UiValueSchemas schemas) {
  final call = schemas.call('action', depth);
  return AnyOfSchema([
    ObjectSchema(
      properties: {
        'event': ObjectSchema(
          properties: {
            'name': const Schema.string(description: 'The event name.'),
            'userMessage': schemas.type(UiType.dynamicString, depth),
            'context': MapSchema(
              values: schemas.type(UiType.dynamicValue, depth),
              description: 'Values sent with the event.',
            ),
          },
          required: ['name'],
        ),
      },
      required: ['event'],
      description: 'Sends an event to the agent.',
    ),
    if (call != null)
      ObjectSchema(
        properties: {'functionCall': call},
        required: ['functionCall'],
        description: 'Calls a function on the renderer.',
      ),
  ]);
}
