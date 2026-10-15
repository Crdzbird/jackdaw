import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

final _menus = UiCatalog(
  id: 'menus',
  components: [
    UiComponentDefinition(
      name: 'Menu',
      description: 'A menu.',
      props: ObjectSchema(properties: {'children': UiType.childList.ref()}),
      allowedParents: const ['Surface'],
      allowedChildren: const ['Item'],
    ),
    UiComponentDefinition(
      name: 'Item',
      description: 'An item.',
      props: ObjectSchema(properties: {'child': UiType.child.ref()}),
      allowedParents: const ['Menu'],
    ),
  ],
);

UiSurface surface(UiCatalog catalog, List<UiComponent> components) {
  final surface = UiSurface('s', catalog);
  for (final c in components) {
    surface.components[c.id] = c;
  }
  return surface;
}

List<String> problems(UiSurface s, {int maxDepth = 32}) => [
  for (final p in uiTreeProblems(s, maxDepth: maxDepth))
    '${p.code.wire} ${p.path} ${p.message}',
];

void main() {
  test('an empty surface has no problems and a rootless one does', () {
    expect(problems(surface(basicCatalog, [])), isEmpty);
    expect(
      problems(surface(basicCatalog, [const UiComponent('a', 'Divider', {})])),
      ['VALIDATION_FAILED /components No component has the id root.'],
    );
  });

  test('cycles, depth and unknown components are reported', () {
    final cycle = surface(basicCatalog, [
      const UiComponent('root', 'Card', {'child': 'a'}),
      const UiComponent('a', 'Card', {'child': 'root'}),
    ]);
    expect(problems(cycle), [
      'INTEGRITY_ERROR /components/root The component root contains itself.',
    ]);
    final deep = surface(basicCatalog, [
      const UiComponent('root', 'Card', {'child': 'a'}),
      const UiComponent('a', 'Card', {'child': 'b'}),
      const UiComponent('b', 'Divider', {}),
    ]);
    const unreachable =
        'VALIDATION_FAILED /components/b '
        'The component b is not reachable from root, so it is not shown.';
    expect(problems(deep, maxDepth: 1), [
      'VALIDATION_FAILED /components/a Components are nested more than 1 deep.',
      unreachable,
    ]);
    final unknown = surface(basicCatalog, [
      const UiComponent('root', 'Blink', {}),
    ]);
    expect(problems(unknown), [
      'VALIDATION_FAILED /components/root The catalog has no component Blink.',
    ]);
  });

  test('tabs, templates and placement rules are followed', () {
    final tabs = surface(basicCatalog, [
      const UiComponent('root', 'Tabs', {
        'tabs': [
          {'title': 'A', 'child': 'list'},
        ],
      }),
      const UiComponent('list', 'List', {
        'children': {'componentId': 'row', 'path': '/rows'},
      }),
      const UiComponent('row', 'Text', {'text': 'x'}),
    ]);
    expect(problems(tabs), isEmpty);
    final menus = surface(_menus, [
      const UiComponent('root', 'Menu', {
        'children': ['ok', 'nested'],
      }),
      const UiComponent('ok', 'Item', {}),
      const UiComponent('nested', 'Menu', {'children': 'not a list'}),
    ]);
    expect(problems(menus), [
      'UNALLOWED_PARENT /components/nested Menu may only be placed in Surface.',
      'UNALLOWED_CHILD /components/nested Menu may only contain Item.',
    ]);
  });
}
