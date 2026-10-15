import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import '../ui_tree_fixtures.dart';

void main() {
  test('a tree becomes one createSurface with ids for every component', () {
    final messages = uiTreeMessages(signupTree, basicCatalog);
    final body = (messages.single! as Map)['createSurface']! as Map;
    final components = body['components']! as List;
    expect(
      [for (final c in components) (c! as Map)['id']],
      ['root', 'textField1', 'button1', 'text1', 'tabs1', 'list1', 'text2'],
    );
    expect((components.first! as Map)['children'], [
      'textField1',
      'button1',
      'tabs1',
    ]);
    expect((components[2]! as Map)['child'], 'text1');
    expect(((components[4]! as Map)['tabs']! as List).single, {
      'title': 'More',
      'child': 'list1',
    });
    expect((components[5]! as Map)['children'], {
      'componentId': 'text2',
      'path': '/items',
    });
    expect(body['dataModel'], signupTree['dataModel']);
    final surfaces = UiSurfaces(basicCatalog);
    expect(surfaces.applyAll(messages), isEmpty);
  });

  test('unknown components and a missing root are kept for validation', () {
    final odd = uiTreeMessages({
      'surfaceId': 's',
      'root': {'component': 'Marquee', 'speed': 3},
    }, basicCatalog);
    final body = (odd.single! as Map)['createSurface']! as Map;
    expect(body['components'], [
      {'id': 'root', 'component': 'Marquee', 'speed': 3},
    ]);
    expect(body.containsKey('dataModel'), isFalse);
    final empty = uiTreeMessages({'surfaceId': 's'}, basicCatalog);
    expect(((empty.single! as Map)['createSurface']! as Map)['components'], [
      {'id': 'root'},
    ]);
  });
}
