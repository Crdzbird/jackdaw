import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import '../ui_fixtures.dart';

Message call(String id, String name, Object? messages) => Message(
  role: Role.assistant,
  parts: [
    ToolCallPart(id: id, name: name, arguments: {'messages': messages}),
  ],
);

Message result(String id, String name, {bool error = false}) => Message(
  role: Role.tool,
  parts: [ToolResultPart(callId: id, name: name, output: 'x', isError: error)],
);

void main() {
  test('successful render calls are applied again in order', () {
    final changed = {
      'version': 'v1.0',
      'createSurface': {
        'surfaceId': 'signup',
        'components': [
          {'id': 'root', 'component': 'Column', 'children': <Object?>[]},
          {'id': 'extra', 'component': 'Divider'},
        ],
      },
    };
    final surfaces = UiSurfaces(basicCatalog);
    uiReplay(surfaces, [
      Message.user('Sign me up'),
      call('a', 'render_ui', [formSurface]),
      result('a', 'render_ui'),
      call('b', 'render_ui', [changed]),
      result('b', 'render_ui'),
      call('c', 'render_ui', [listMessages.first]),
      result('c', 'render_ui', error: true),
      call('d', 'other', [listMessages.first]),
      result('d', 'other'),
      call('e', 'render_ui', 'not a list'),
      result('e', 'render_ui'),
    ]);
    expect(surfaces.surfaces.keys, ['signup']);
    final root = surfaces.surfaces['signup']!.root!;
    expect(root.props['children'], ['extra']);
  });

  test('orphans can be left alone', () {
    final surfaces = UiSurfaces(basicCatalog);
    uiReplay(
      surfaces,
      [
        call('a', 'ui', [
          {
            'version': 'v1.0',
            'createSurface': {
              'surfaceId': 's',
              'components': [
                {'id': 'root', 'component': 'Column', 'children': <Object?>[]},
                {'id': 'x', 'component': 'Divider'},
              ],
            },
          },
        ]),
        result('a', 'ui'),
      ],
      tool: 'ui',
      adoptOrphans: false,
    );
    expect(surfaces.surfaces['s']!.root!.props['children'], isEmpty);
  });
}
