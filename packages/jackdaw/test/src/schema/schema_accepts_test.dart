import 'dart:convert';

import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import '../ui/ui_fixtures.dart';

const List<Object?> _values = [
  null,
  true,
  1,
  1.5,
  'red',
  'blue',
  [],
  [1, 'a'],
  ['red', 'red', 'red'],
  {},
  {'kind': 'dot', 'x': 1},
  {'kind': 'dot', 'x': 'one'},
  {'kind': 'line', 'from': 1, 'to': 2},
  {'kind': 'line', 'from': 1},
  {'kind': 'other'},
  {'name': 'a', 'extra': 1},
  {'name': 'a'},
];

final List<Schema> _schemas = [
  const Schema.string(),
  const Schema.string(enumValues: ['red']),
  const Schema.number(),
  const Schema.integer(),
  const Schema.boolean(),
  const Schema.raw({}),
  const Schema.array(items: Schema.string(), minItems: 1, maxItems: 2),
  const Schema.array(items: Schema.string(), prefixItems: [Schema.integer()]),
  const Schema.map(values: Schema.integer()),
  const ObjectSchema(properties: {'name': Schema.string()}),
  const ObjectSchema(properties: {'name': Schema.string()}, required: ['name']),
  const AnyOfSchema([Schema.string(), Schema.integer()]),
  const UnionSchema(
    discriminator: 'kind',
    variants: {
      'dot': ObjectSchema(properties: {'x': Schema.number()}),
      'line': ObjectSchema(
        properties: {'from': Schema.number(), 'to': Schema.number()},
        required: ['from', 'to'],
      ),
    },
  ),
  const Schema.summarized(Schema.integer(), summary: 'n'),
];

void main() {
  test('accepts agrees with validate for every schema type', () {
    for (final schema in _schemas) {
      for (final value in _values) {
        expect(
          schema.accepts(value),
          schema.validate(value).isEmpty,
          reason: '${schema.toJson()} on ${jsonEncode(value)}',
        );
      }
    }
  });

  test('accepts agrees with validate on UI messages', () {
    final message = UiSchemas(basicCatalog).message;
    final broken = jsonDecode(jsonEncode(formSurface)) as Map<String, Object?>;
    ((broken['createSurface']! as Map)['components']! as List).add({
      'id': 'x',
      'component': 'Slider',
      'value': 'high',
    });
    for (final value in <Object?>[formSurface, broken, {}, null]) {
      expect(message.accepts(value), message.validate(value).isEmpty);
      expect(
        [for (final v in message.check(value)) '$v'],
        [for (final v in message.validate(value)) '$v'],
      );
    }
    expect(message.accepts(formSurface), isTrue);
    expect(message.accepts(broken), isFalse);
  });
}
