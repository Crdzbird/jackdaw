import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('pointers split into unescaped tokens and back', () {
    expect(jsonPointerTokens(''), isEmpty);
    expect(jsonPointerTokens('/'), isEmpty);
    expect(jsonPointerTokens('/a/b~1c/d~0e'), ['a', 'b/c', 'd~e']);
    expect(jsonPointer(['a', 'b/c', 'd~e', 0]), '/a/b~1c/d~0e/0');
  });

  test('relative paths resolve against their scope', () {
    expect(resolveJsonPointer('/abs', '/users/0'), '/abs');
    expect(resolveJsonPointer('name', '/users/0'), '/users/0/name');
    expect(resolveJsonPointer('name', '/'), '/name');
  });

  test('violation paths become pointers', () {
    expect(violationPointer(r'$'), '');
    expect(violationPointer(r'$.a[2].b'), '/a/2/b');
  });
}
