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
  test('runs calls concurrently and keeps call order', () async {
    final box = ToolBox([echo('a'), echo('b')]);
    final results = await box.runAll(const [
      ToolCallPart(id: '1', name: 'b', arguments: {}),
      ToolCallPart(id: '2', name: 'a', arguments: {}),
    ]);
    expect(results.map((r) => r.output), [
      {'from': 'b'},
      {'from': 'a'},
    ]);
    expect(box.specs.map((s) => s.name), ['a', 'b']);
  });

  test('reports unknown tools to the model', () async {
    final result = await ToolBox(const [])
        .run(const ToolCallPart(id: '1', name: 'nope', arguments: {}));
    expect(result.isError, isTrue);
    expect(result.output, {'error': 'unknown tool nope'});
  });

  test('rejects duplicate names', () {
    expect(() => ToolBox([echo('a'), echo('a')]), throwsArgumentError);
  });
}
