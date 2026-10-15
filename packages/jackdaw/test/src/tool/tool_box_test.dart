import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw/src/tool/tool_box.dart';
import 'package:test/test.dart';

Tool<Object?> echo(String name) => Tool<Object?>(
  name: name,
  description: 'echo',
  input: const ObjectSchema(properties: {}, additionalProperties: true),
  decode: (json) => json,
  run: (input) => {'from': name},
);

void main() {
  test('looks tools up by name and lists their specs', () {
    final box = ToolBox([echo('a'), echo('b')]);
    expect(box['a']!.name, 'a');
    expect(box['missing'], isNull);
    expect(box.specsFor(const []).map((s) => s.name), ['a', 'b']);
  });

  test('rejects duplicate names', () {
    expect(() => ToolBox([echo('a'), echo('a')]), throwsArgumentError);
  });
}
