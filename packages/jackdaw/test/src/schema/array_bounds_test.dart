import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw/src/grammar/gbnf_members.dart';
import 'package:test/test.dart';

List<String> check(Schema schema, Object? value) =>
    schema.validate(value).map((v) => '$v').toList();

void main() {
  const tags = Schema.array(items: Schema.string(), minItems: 1, maxItems: 2);

  test('arrays check their bounds and serialize them', () {
    expect(check(tags, ['a']), isEmpty);
    expect(check(tags, <Object?>[]), [r'$ expected at least 1 items']);
    expect(check(tags, ['a', 'b', 'c']), [r'$ expected at most 2 items']);
    expect(tags.toJson(), {
      'type': 'array',
      'items': {'type': 'string'},
      'minItems': 1,
      'maxItems': 2,
    });
  });

  test('bounds read back from JSON', () {
    final read = schemaFromJson(tags.toJson()) as ArraySchema;
    expect((read.minItems, read.maxItems), (1, 2));
    for (final bad in [-1, 'x']) {
      expect(
        schemaFromJson({
          'type': 'array',
          'items': {'type': 'string'},
          'minItems': bad,
        }),
        isA<RawSchema>(),
      );
    }
    expect(
      schemaFromJson({
        'type': 'array',
        'items': {'type': 'string'},
        'maxItems': 1.5,
      }),
      isA<RawSchema>(),
    );
  });

  test('bounds become grammar repetitions', () {
    expect(gbnfRepeat('"["', 'x', '"]"'), '"[" ws (x (ws "," ws x)*)? ws "]"');
    expect(gbnfRepeat('"["', 'x', '"]"', 1), '"[" ws x (ws "," ws x)* ws "]"');
    expect(
      gbnfRepeat('"["', 'x', '"]"', 3),
      '"[" ws x (ws "," ws x){2,} ws "]"',
    );
    expect(
      gbnfRepeat('"["', 'x', '"]"', 0, 4),
      '"[" ws (x (ws "," ws x){0,3})? ws "]"',
    );
    expect(GbnfCompiler().compile(tags), contains('{0,1}'));
    expect(() => gbnfRepeat('[', 'x', ']', 2, 1), throwsArgumentError);
    expect(() => gbnfRepeat('[', 'x', ']', 0, 0), throwsArgumentError);
  });
}
