import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import '../ui_fixtures.dart';

Future<ToolResultPart> call(Tool<List<Object?>> tool, Object? messages) =>
    tool.invoke(
      ToolCallPart(id: 'c', name: tool.name, arguments: {'messages': messages}),
    );

void main() {
  test('the tool applies messages and names the surfaces it touched', () async {
    final surfaces = UiSurfaces(basicCatalog);
    final tool = uiTool(surfaces);
    expect(tool.name, 'render_ui');
    expect(tool.spec.input.required, ['messages']);
    final result = await call(tool, [formSurface]);
    expect(result.isError, isFalse);
    final output = result.output! as Map;
    expect(output['shown'], ['signup']);
    expect(output['note'], startsWith('The user sees it now.'));
    expect(surfaces.surfaces.keys, ['signup']);
  });

  test('problems come back for the model to fix', () async {
    final surfaces = UiSurfaces(basicCatalog);
    final result = await call(uiTool(surfaces, name: 'ui'), [
      {
        'version': 'v1.0',
        'createSurface': {
          'surfaceId': 's',
          'components': [
            {'id': 'root', 'component': 'Card', 'child': 'gone'},
          ],
        },
      },
    ]);
    final problems = (result.output! as Map)['problems']! as List;
    expect(problems.single, {
      'code': 'VALIDATION_FAILED',
      'surfaceId': 's',
      'path': '/components/root/child',
      'message': 'There is no component with the id gone.',
    });
  });

  test('messages outside the reply schema are refused', () async {
    final result = await call(uiTool(UiSurfaces(basicCatalog)), [
      formSurface,
      formSurface,
    ]);
    expect(result.isError, isTrue);
  });

  test('local models read the catalog guide for the messages', () {
    final json = promptSchemaJson(uiTool(UiSurfaces(basicCatalog)).input);
    final messages = (json['properties']! as Map)['messages']! as Map;
    expect(messages['description'], uiCatalogGuide(basicCatalog));
  });

  test('warnings do not undo a batch and come back from the tool', () async {
    final surfaces = UiSurfaces(basicCatalog);
    final result = await uiTool(surfaces).invoke(
      const ToolCallPart(
        id: 'c',
        name: 'render_ui',
        arguments: {
          'messages': [
            {
              'version': 'v1.0',
              'createSurface': {
                'surfaceId': 's',
                'components': [
                  {'id': 'root', 'component': 'Divider'},
                  {'id': 'lost', 'component': 'Divider'},
                ],
              },
            },
          ],
        },
      ),
    );
    final output = result.output! as Map;
    expect(output['shown'], ['s']);
    expect(
      (output['warnings']! as List).single,
      containsPair('path', '/components/lost'),
    );
    expect(surfaces.surfaces['s']!.components, hasLength(2));
  });
}
