import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

Map<String, Object?> create(List<Object?> components) => {
  'version': 'v1.0',
  'createSurface': {'surfaceId': 's', 'components': components},
};

List<Object?> componentsOf(Object? message) =>
    ((message! as Map)['createSurface']! as Map)['components']! as List;

void main() {
  test('unreferenced components join the root children in order', () {
    final message = create([
      {
        'id': 'root',
        'component': 'Column',
        'children': ['a'],
      },
      {'id': 'a', 'component': 'Text', 'text': 'a'},
      {'id': 'card', 'component': 'Card', 'child': 'inner'},
      {'id': 'inner', 'component': 'Text', 'text': 'i'},
      {'id': 'b', 'component': 'Mystery'},
      'not a component',
    ]);
    final adopted = uiAdoptOrphans([message], basicCatalog).single;
    expect((componentsOf(adopted).first! as Map)['children'], [
      'a',
      'card',
      'b',
    ]);
    expect(componentsOf(adopted).last, 'not a component');
    expect(UiSurfaces(basicCatalog).applyAll([adopted]), isNotEmpty);
  });

  test('other messages and complete surfaces are left alone', () {
    final complete = create([
      {
        'id': 'root',
        'component': 'Column',
        'children': ['a'],
      },
      {'id': 'a', 'component': 'Divider'},
    ]);
    final card = create([
      {'id': 'root', 'component': 'Card', 'child': 'a'},
      {'id': 'b', 'component': 'Divider'},
    ]);
    final rootless = create([
      {'id': 'a', 'component': 'Divider'},
    ]);
    final update = {
      'version': 'v1.0',
      'updateComponents': {
        'surfaceId': 's',
        'components': [
          {'id': 'root', 'component': 'Column', 'children': <Object?>[]},
          {'id': 'b', 'component': 'Divider'},
        ],
      },
    };
    final all = [complete, card, rootless, update, 'x'];
    final out = uiAdoptOrphans(all, basicCatalog);
    for (var i = 0; i < all.length; i++) {
      expect(identical(out[i], all[i]), isTrue, reason: '$i');
    }
  });

  test('the tool adopts orphans unless told not to', () async {
    Future<Object?> show({required bool adopt}) async {
      final surfaces = UiSurfaces(basicCatalog);
      await uiTool(
        surfaces,
        adoptOrphans: adopt,
        format: UiFormat.messages,
      ).invoke(
        ToolCallPart(
          id: 'c',
          name: 'render_ui',
          arguments: {
            'messages': [
              create([
                {'id': 'root', 'component': 'Column', 'children': <Object?>[]},
                {'id': 'a', 'component': 'Divider'},
              ]),
            ],
          },
        ),
      );
      return surfaces.surfaces['s']!.root!.props['children'];
    }

    expect(await show(adopt: true), ['a']);
    expect(await show(adopt: false), isEmpty);
  });
}
