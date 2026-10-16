import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('a schema is compiled once and its grammar reused', () {
    const schema = ObjectSchema(properties: {'name': Schema.string()});
    final first = gbnfGrammar(schema);
    expect(first, GbnfCompiler().compile(schema));
    expect(identical(gbnfGrammar(schema), first), isTrue);
  });
}
