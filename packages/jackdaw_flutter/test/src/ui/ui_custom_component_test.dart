import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

final UiCatalog _catalog = UiCatalog(
  id: 'test/badges',
  components: [
    ...basicCatalog.components,
    const UiComponentDefinition(
      name: 'Badge',
      description: 'A short label.',
      props: ObjectSchema(
        properties: {'label': Schema.string()},
        required: ['label'],
      ),
    ),
  ],
  functions: basicCatalog.functions,
);

Widget _badge(UiNode node) => Chip(label: Text('badge ${node.text('label')}'));

void main() {
  testWidgets('every view draws custom components with the controller '
      'builders', (tester) async {
    final controller = UiSurfaceController(
      _catalog,
      builders: {...basicUiBuilders, 'Badge': _badge},
    );
    final problems = controller.applyAll([
      {
        'version': 'v1.0',
        'createSurface': {
          'surfaceId': 's',
          'catalogId': 'test/badges',
          'components': [
            {
              'id': 'root',
              'component': 'Column',
              'children': ['b'],
            },
            {'id': 'b', 'component': 'Badge', 'label': 'new'},
          ],
        },
      },
    ]);
    expect(problems, isEmpty);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiSurfaceView(controller: controller, surfaceId: 's'),
        ),
      ),
    );
    expect(find.text('badge new'), findsOneWidget);
  });
}
