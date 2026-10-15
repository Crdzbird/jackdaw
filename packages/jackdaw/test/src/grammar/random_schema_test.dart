@TestOn('vm')
library;

import 'dart:io';
import 'dart:math';

import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import 'random_schemas.dart';

final RegExp _defined = RegExp('^([a-z0-9]+) ::=', multiLine: true);
final RegExp _referenced = RegExp(
  r'\b(rule[0-9]+|ws|string|integer|number|'
  r'boolean|value|jobject|jarray|char)\b',
);

void main() {
  test('every random schema compiles to a closed grammar', () {
    final random = Random(42);
    final corpus = Platform.environment['JACKDAW_GRAMMAR_CORPUS'];
    for (var i = 0; i < 500; i++) {
      final schema = randomSchema(random);
      final grammar = GbnfCompiler().compile(schema);
      final defined = {
        for (final m in _defined.allMatches(grammar)) m.group(1)!,
      };
      final outsideLiterals = grammar.replaceAll(
        RegExp(r'"(\\.|[^"\\])*"'),
        '""',
      );
      final used = {
        for (final m in _referenced.allMatches(outsideLiterals)) m.group(1)!,
      };
      expect(defined, contains('root'), reason: grammar);
      expect(used.difference(defined), isEmpty, reason: grammar);
      final calls = toolCallGrammar([
        ToolSpec(
          name: 'tool_$i',
          description: 'random',
          input: schema is ObjectSchema
              ? schema
              : ObjectSchema(properties: {'x': schema}),
        ),
      ], answer: random.nextBool() ? schema : null);
      expect(calls, startsWith('root ::= '));
      if (corpus != null) {
        File('$corpus/schema_$i.gbnf').writeAsStringSync(grammar);
        File('$corpus/tools_$i.gbnf').writeAsStringSync(calls);
      }
    }
  });
}
