import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';
import 'package:jackdaw_flutter/src/ui/ui_bound_paths.dart';

Map<String, Object?> _text(String id, String path) => {
  'id': id,
  'component': 'Text',
  'text': {'@path': path},
};

void main() {
  test('bound paths cover bindings, calls, templates and formats', () {
    expect(
      uiBoundPaths({
        'text': {'@path': 'name'},
        'checks': [
          {
            '@call': 'required',
            'args': {
              'value': {'@path': '/email'},
            },
          },
        ],
        'children': {'componentId': 'row', 'path': '/items'},
      }, '/form'),
      {'/form/name', '/email', '/items'},
    );
    expect(uiBoundPaths({'text': r'Hi ${/name}'}, ''), {'/'});
  });

  testWidgets('a write redraws only the components that read it', (
    tester,
  ) async {
    final built = <String, int>{};
    final controller =
        UiSurfaceController(
          basicCatalog,
          builders: {
            ...basicUiBuilders,
            'Text': (node) {
              built.update(node.component.id, (n) => n + 1, ifAbsent: () => 1);
              return Text(node.text('text') ?? '');
            },
          },
        )..applyAll([
          {
            'version': 'v1.0',
            'createSurface': {
              'surfaceId': 's',
              'components': [
                {
                  'id': 'root',
                  'component': 'Column',
                  'children': ['a', 'b'],
                },
                _text('a', '/a'),
                _text('b', '/b'),
              ],
              'dataModel': {'a': 'one', 'b': 'two'},
            },
          },
        ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiSurfaceView(controller: controller, surfaceId: 's'),
        ),
      ),
    );
    expect(built, {'a': 1, 'b': 1});
    controller.write('s', '/a', 'three');
    await tester.pump();
    expect(find.text('three'), findsOneWidget);
    expect(built, {'a': 2, 'b': 1});
    controller.applyAll([
      {
        'version': 'v1.0',
        'updateDataModel': {'surfaceId': 's', 'path': '/b', 'value': 'four'},
      },
    ]);
    await tester.pump();
    expect(find.text('four'), findsOneWidget);
    expect(built, {'a': 2, 'b': 2});
  });
}
