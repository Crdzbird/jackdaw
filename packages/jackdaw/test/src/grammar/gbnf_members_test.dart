import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw/src/grammar/gbnf_members.dart';
import 'package:test/test.dart';

void main() {
  test('required members are fixed and optional ones may be skipped', () {
    expect(gbnfObjectBody([]), '"{" ws "}"');
    expect(
      gbnfObjectBody([('a', true), ('b', false), ('c', true)]),
      '"{" ws a (ws "," ws b)? (ws "," ws c) ws "}"',
    );
    expect(
      gbnfObjectBody([('a', false), ('b', true)]),
      '"{" ws (a (ws "," ws b) | b) ws "}"',
    );
    expect(
      gbnfObjectBody([('a', false), ('b', false)]),
      '"{" ws ((a (ws "," ws b)? | b))? ws "}"',
    );
  });

  test('shared schemas compile to one rule', () {
    const city = ObjectSchema(
      properties: {'name': Schema.string()},
      required: ['name'],
    );
    final grammar = GbnfCompiler().compile(
      const ObjectSchema(
        properties: {'from': city, 'to': city},
        required: ['from', 'to'],
      ),
    );
    expect(r'"\"name\""'.allMatches(grammar), hasLength(1));
    expect(grammar, contains(r'"\"from\"" ws ":" ws rule0'));
    expect(grammar, contains(r'"\"to\"" ws ":" ws rule0'));
  });

  test('anyOf compiles to one alternative per option', () {
    final grammar = GbnfCompiler().compile(
      const Schema.anyOf([
        Schema.string(),
        ObjectSchema(
          properties: {'@path': Schema.string()},
          required: ['@path'],
        ),
      ]),
    );
    expect(grammar, startsWith('root ::= rule1\n'));
    expect(grammar, contains('rule1 ::= string | rule0'));
    expect(
      () => GbnfCompiler().compile(const Schema.anyOf([])),
      throwsArgumentError,
    );
  });
}
