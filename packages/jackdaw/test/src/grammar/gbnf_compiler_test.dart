import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

String compile(Schema schema) => GbnfCompiler().compile(schema);

void main() {
  test('primitives reference shared rules', () {
    expect(compile(const Schema.string()), startsWith('root ::= string\n'));
    expect(compile(const Schema.integer()), contains('integer ::= "-"?'));
    expect(compile(const Schema.number()), contains('number ::= '));
    expect(compile(const Schema.boolean()), endsWith('"true" | "false"'));
  });

  test('enums become escaped JSON literals', () {
    final grammar = compile(const Schema.string(enumValues: ['a"b', 'c']));
    expect(grammar, contains(r'rule0 ::= "\"a\\\"b\"" | "\"c\""'));
  });

  test('objects list every property in order', () {
    final grammar = compile(
      const ObjectSchema(
        properties: {'name': Schema.string(), 'age': Schema.integer()},
      ),
    );
    expect(
      grammar,
      contains(
        r'rule0 ::= "{" ws "\"name\"" ws ":" ws string ws "," ws '
        r'"\"age\"" ws ":" ws integer ws "}"',
      ),
    );
    expect(grammar, contains('ws ::= '));
  });

  test('empty objects and nested arrays', () {
    final grammar = compile(
      const Schema.array(items: ObjectSchema(properties: {})),
    );
    expect(grammar, contains('root ::= rule1'));
    expect(grammar, contains('rule0 ::= "{" ws "}"'));
    expect(
      grammar,
      contains('rule1 ::= "[" ws (rule0 (ws "," ws rule0)*)? ws "]"'),
    );
  });

  test('each primitive is emitted once', () {
    final grammar = compile(
      const ObjectSchema(
        properties: {'a': Schema.string(), 'b': Schema.string()},
      ),
    );
    expect('string ::='.allMatches(grammar), hasLength(1));
  });

  test('raw schemas compile to any JSON value', () {
    final grammar = GbnfCompiler().compile(
      const ObjectSchema(properties: {'v': Schema.raw({})}),
    );
    expect(grammar, contains('ws ":" ws value ws "}"'));
    expect(grammar, contains('value ::= jobject | jarray | string | number'));
    expect(grammar, contains('jarray ::='));
    expect(grammar, contains('string ::='));
    expect(grammar, contains('number ::='));
  });

  test('unions compile to one alternative per variant', () {
    final grammar = compile(
      const Schema.union(
        discriminator: 'kind',
        variants: {
          'a': ObjectSchema(properties: {}),
          'b': ObjectSchema(properties: {'n': Schema.integer()}),
        },
      ),
    );
    expect(grammar, startsWith('root ::= rule4\n'));
    expect(grammar, contains('rule4 ::= rule1 | rule3\n'));
    expect(
      grammar,
      contains(
        r'rule3 ::= "{" ws "\"kind\"" ws ":" ws rule2 ws "," ws '
        r'"\"n\"" ws ":" ws integer ws "}"',
      ),
    );
    expect(grammar, contains(r'rule2 ::= "\"b\""'));
    expect(
      () => compile(const Schema.union(discriminator: 'kind', variants: {})),
      throwsArgumentError,
    );
  });
}
