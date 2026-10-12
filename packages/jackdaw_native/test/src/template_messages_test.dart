import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/src/template_messages.dart';
import 'package:test/test.dart';

void main() {
  const schema = Schema.boolean();

  test('passes messages through without a schema', () {
    expect(templateMessages([Message.user('hi')], null), [('user', 'hi')]);
  });

  test('extends an existing system message with the schema', () {
    final pairs = templateMessages([
      Message.system('Be brief.'),
      Message.user('ok?'),
    ], schema);
    expect(pairs.first.$1, 'system');
    expect(pairs.first.$2, startsWith('Be brief.\n\nReply with JSON only'));
    expect(pairs.last, ('user', 'ok?'));
  });

  test('adds a system message when there is none', () {
    final pairs = templateMessages([Message.user('ok?')], schema);
    expect(pairs, hasLength(2));
    expect(pairs.first.$2, contains('{"type":"boolean"}'));
  });
}
