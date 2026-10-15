import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

List<String> check(Schema schema, Object? value) =>
    schema.validate(value).map((v) => '$v').toList();

void main() {
  const scores = Schema.map(values: Schema.integer(), description: 'Scores');

  test('a map serializes its value schema', () {
    expect(scores.toJson(), {
      'type': 'object',
      'description': 'Scores',
      'additionalProperties': {'type': 'integer'},
    });
  });

  test('every value is checked under its key', () {
    expect(check(scores, {'ana': 3, 'bo': 4}), isEmpty);
    expect(check(scores, <String, Object?>{}), isEmpty);
    expect(check(scores, {'ana': 'x'}), [r'$.ana expected an integer']);
    expect(check(scores, [1]), [r'$ expected an object']);
    expect(check(scores, {1: 2}), [r'$ expected an object']);
  });

  test('maps compile to repeated string keys', () {
    final grammar = GbnfCompiler().compile(scores);
    expect(
      grammar,
      contains(
        'rule0 ::= "{" ws (string ws ":" ws integer '
        '(ws "," ws string ws ":" ws integer)*)? ws "}"',
      ),
    );
    expect(grammar, contains('string ::= '));
  });

  test('an object with typed additional properties reads as a map', () {
    final read = schemaFromJson(scores.toJson());
    expect(read, isA<MapSchema>());
    expect(read.toJson(), scores.toJson());
    expect(
      schemaFromJson({
        'type': 'object',
        'additionalProperties': {'minLength': 1},
      }),
      isA<RawSchema>(),
    );
  });
}
