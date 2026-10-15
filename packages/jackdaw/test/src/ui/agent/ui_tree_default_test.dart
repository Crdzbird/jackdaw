import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import '../support/replies_model.dart';
import '../ui_tree_fixtures.dart';

void main() {
  test('the tool takes a tree by default', () async {
    final surfaces = UiSurfaces(basicCatalog);
    final tool = uiTool(surfaces);
    expect(tool.input.required, ['surfaceId', 'root']);
    final result = await tool.invoke(
      const ToolCallPart(id: 'c', name: 'render_ui', arguments: signupTree),
    );
    expect(result.isError, isFalse);
    expect(surfaces.surfaces['signup']!.components, hasLength(7));
    final restored = UiSurfaces(basicCatalog);
    uiReplay(restored, [
      const Message(
        role: Role.assistant,
        parts: [
          ToolCallPart(id: 'c', name: 'render_ui', arguments: signupTree),
        ],
      ),
      Message(role: Role.tool, parts: [result]),
    ]);
    expect(restored.surfaces['signup']!.root!.type, 'Column');
  });

  test('generateUi asks for a tree by default', () async {
    final surfaces = UiSurfaces(basicCatalog);
    final model = RepliesModel([signupTree]);
    final problems = await generateUi(model, [
      Message.user('Sign up'),
    ], surfaces);
    expect(problems, isEmpty);
    expect(model.requests.single.responseSchema, same(surfaces.schemas.tree));
    expect(surfaces.surfaces.keys, ['signup']);
  });
}
