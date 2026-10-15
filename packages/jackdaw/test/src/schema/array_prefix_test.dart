import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw/src/grammar/gbnf_members.dart';
import 'package:test/test.dart';

void main() {
  const pair = Schema.array(
    prefixItems: [Schema.string()],
    items: Schema.integer(),
    minItems: 1,
  );

  test('prefix items check the first elements', () {
    expect(pair.validate(['a', 1, 2]), isEmpty);
    expect(pair.validate([1, 2]).map((v) => '$v'), [r'$[0] expected a string']);
    expect(pair.toJson(), {
      'type': 'array',
      'prefixItems': [
        {'type': 'string'},
      ],
      'items': {'type': 'integer'},
      'minItems': 1,
    });
  });

  test('prefix items read back from JSON', () {
    final read = schemaFromJson(pair.toJson()) as ArraySchema;
    expect(read.prefixItems.single, isA<StringSchema>());
    expect(
      schemaFromJson({
        'type': 'array',
        'items': {'type': 'string'},
        'prefixItems': ['x'],
      }),
      isA<RawSchema>(),
    );
  });

  test('prefix items come first in the grammar', () {
    expect(
      gbnfRepeat('"["', 'x', '"]"', min: 1, prefix: ['p']),
      '"[" ws p (ws "," ws x)* ws "]"',
    );
    expect(
      gbnfRepeat('"["', 'x', '"]"', min: 2, max: 2, prefix: ['p', 'q']),
      '"[" ws p ws "," ws q ws "]"',
    );
    expect(
      gbnfRepeat('"["', 'x', '"]"', min: 1, max: 3, prefix: ['p']),
      '"[" ws p (ws "," ws x){0,2} ws "]"',
    );
    expect(gbnfRepeat('"["', 'x', '"]"', max: 1), '"[" ws (x)? ws "]"');
    expect(() => gbnfRepeat('[', 'x', ']', prefix: ['p']), throwsArgumentError);
  });
}
