import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  const point = ObjectSchema(
    properties: {'x': Schema.number(), 'y': Schema.number()},
    required: ['x', 'y'],
  );

  test('schemas used once are written in place', () {
    const line = ObjectSchema(properties: {'from': point});
    expect(sharedSchemaJson(line), line.toJson());
  });

  test('composite schemas used twice are written once under defs', () {
    const line = ObjectSchema(
      properties: {'from': point, 'to': point, 'label': Schema.string()},
    );
    final json = sharedSchemaJson(line);
    final properties = json['properties']! as Map<String, Object?>;
    expect(properties['from'], {r'$ref': r'#/$defs/d0'});
    expect(properties['to'], {r'$ref': r'#/$defs/d0'});
    expect(properties['label'], {'type': 'string'});
    expect(json[r'$defs'], {'d0': point.toJson()});
  });

  test('shared schemas inside shared schemas are referenced too', () {
    const pair = Schema.array(items: point);
    const shape = ObjectSchema(
      properties: {
        'a': pair,
        'b': pair,
        'c': Schema.anyOf([point, Schema.string()]),
      },
    );
    final json = sharedSchemaJson(shape);
    final defs = json[r'$defs']! as Map<String, Object?>;
    expect(defs.keys, ['d0', 'd1']);
    expect(defs['d0'], {
      'type': 'array',
      'items': {r'$ref': r'#/$defs/d1'},
    });
    expect(defs['d1'], point.toJson());
  });
}
