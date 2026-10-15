import 'package:jackdaw/src/schema/schema.dart';

const Schema _surfaceId = Schema.string(description: 'The surface id.');

const Schema _anyValue = Schema.raw({});

/// The A2UI v1.0 version every message carries.
const String uiProtocolVersion = 'v1.0';

/// The schema of the A2UI v1.0 agent-to-renderer messages a model may send
/// for surfaces of the catalog [catalogId], with [components] as the list
/// of components a message carries.
Schema uiMessageSchema(String catalogId, Schema components) => AnyOfSchema([
  uiCreateSurfaceMessage(catalogId, components),
  ...uiUpdateMessages(components),
], description: 'An A2UI v1.0 message.');

/// The schema of a `createSurface` message for the catalog [catalogId].
ObjectSchema uiCreateSurfaceMessage(String catalogId, Schema components) =>
    _envelope(
      'createSurface',
      ObjectSchema(
        properties: {
          'surfaceId': _surfaceId,
          'catalogId': Schema.string(enumValues: [catalogId]),
          'sendDataModel': const Schema.boolean(
            description: 'Whether user input is sent with every action.',
          ),
          'components': components,
          'dataModel': const Schema.map(
            values: _anyValue,
            description: 'The initial data.',
          ),
        },
        required: ['surfaceId'],
        description: 'Creates a surface, optionally with its content.',
      ),
    );

/// The schemas of the messages that change or remove an existing surface.
List<ObjectSchema> uiUpdateMessages(Schema components) => [
  _envelope(
    'updateComponents',
    ObjectSchema(
      properties: {'surfaceId': _surfaceId, 'components': components},
      required: ['surfaceId', 'components'],
      description: 'Adds or replaces components by id.',
    ),
  ),
  _envelope(
    'updateDataModel',
    const ObjectSchema(
      properties: {
        'surfaceId': _surfaceId,
        'path': Schema.string(description: 'Where to write, / if unset.'),
        'value': _anyValue,
      },
      required: ['surfaceId', 'value'],
      description: 'Writes data; a null value deletes the path.',
    ),
  ),
  _envelope(
    'deleteSurface',
    const ObjectSchema(
      properties: {'surfaceId': _surfaceId},
      required: ['surfaceId'],
      description: 'Removes a surface.',
    ),
  ),
];

ObjectSchema _envelope(String name, ObjectSchema body) => ObjectSchema(
  properties: {
    'version': const Schema.string(enumValues: [uiProtocolVersion]),
    name: body,
  },
  required: ['version', name],
);
