import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

List<String> check(Schema schema, Object? value) =>
    schema.validate(value).map((v) => '$v').toList();

void main() {
  test('string schema', () {
    const schema = Schema.string(description: 'name');
    expect(schema.toJson(), {'type': 'string', 'description': 'name'});
    expect(check(schema, 'x'), isEmpty);
    expect(check(schema, 1), [r'$ expected a string']);
  });

  test('string enum', () {
    const schema = Schema.string(enumValues: ['c', 'f']);
    expect(schema.toJson()['enum'], ['c', 'f']);
    expect(check(schema, 'c'), isEmpty);
    expect(check(schema, 'k'), [r'$ expected one of c, f']);
  });

  test('integer schema', () {
    const schema = Schema.integer();
    expect(schema.toJson(), {'type': 'integer'});
    expect(check(schema, 3), isEmpty);
    expect(check(schema, 3.0), isEmpty);
    expect(check(schema, 3.5), [r'$ expected an integer']);
    expect(check(schema, double.infinity), [r'$ expected an integer']);
    expect(check(schema, '3'), [r'$ expected an integer']);
  });

  test('number schema', () {
    const schema = Schema.number();
    expect(schema.toJson(), {'type': 'number'});
    expect(check(schema, 1.5), isEmpty);
    expect(check(schema, true), [r'$ expected a number']);
  });

  test('boolean schema', () {
    const schema = Schema.boolean();
    expect(schema.toJson(), {'type': 'boolean'});
    expect(check(schema, false), isEmpty);
    expect(check(schema, 0), [r'$ expected a boolean']);
  });

  test('violation exposes path and message', () {
    const violation = SchemaViolation(r'$.a', 'is required');
    expect([violation.path, violation.message], [r'$.a', 'is required']);
  });
}
