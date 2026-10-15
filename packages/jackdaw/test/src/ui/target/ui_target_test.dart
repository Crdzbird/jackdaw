import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import '../ui_fixtures.dart';
import '../ui_tree_fixtures.dart';

Map<String, Object?> envelope(String kind, Map<String, Object?> body) => {
  'version': 'v1.0',
  kind: body,
};

void main() {
  test('jackdaw surfaces are a target', () {
    final target = UiTarget.surfaces(basicCatalog);
    expect(target, isA<UiSurfaces>());
    expect(target.show([formSurface]), isEmpty);
    final broken = envelope('updateComponents', {
      'surfaceId': 'signup',
      'components': [
        {'id': 'root', 'component': 'Card', 'child': 'gone'},
      ],
    });
    expect(target.show([broken]), isNotEmpty);
    expect((target as UiSurfaces).surfaces['signup']!.root!.type, 'Column');
    expect(target.show([broken], partial: true), isNotEmpty);
    expect(target.surfaces['signup']!.root!.type, 'Card');
  });

  test(
    'a forward target sends what shows, deleting a surface it recreates',
    () {
      final sent = <List<Map<String, Object?>>>[];
      final target = UiTarget.forward(basicCatalog, send: sent.add);
      expect(target.schemas.catalog, same(basicCatalog));
      expect(target.show([formSurface]), isEmpty);
      expect(target.show([formSurface]), isEmpty);
      expect(sent, hasLength(2));
      expect(sent.last.map((m) => m.keys.last), [
        'deleteSurface',
        'createSurface',
      ]);
      final dangling = envelope('createSurface', {
        'surfaceId': 'x',
        'components': [
          {'id': 'root', 'component': 'Card', 'child': 'gone'},
        ],
      });
      expect(target.show([dangling]), isNotEmpty);
      expect(sent, hasLength(2));
      target.show([dangling], partial: true);
      expect(sent, hasLength(3));
    },
  );

  test('the tool and replay work with any target', () async {
    final sent = <List<Map<String, Object?>>>[];
    final target = UiTarget.forward(basicCatalog, send: sent.add);
    final result = await uiTool(target).invoke(
      const ToolCallPart(id: 'c', name: 'render_ui', arguments: signupTree),
    );
    expect(result.isError, isFalse);
    expect(sent.single.single.keys.last, 'createSurface');
  });
}
