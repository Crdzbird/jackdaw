import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('warnings do not undo a batch and come back from the tool', () async {
    final surfaces = UiSurfaces(basicCatalog);
    final result = await uiTool(surfaces, format: UiFormat.messages).invoke(
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
