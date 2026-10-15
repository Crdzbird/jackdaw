import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import '../ui_fixtures.dart';

Map<String, Object?> envelope(String kind, Map<String, Object?> body) => {
  'version': 'v1.0',
  kind: body,
};

final Map<String, Object?> dangling = envelope('updateComponents', {
  'surfaceId': 'signup',
  'components': [
    {'id': 'root', 'component': 'Card', 'child': 'gone'},
  ],
});

void main() {
  test('an atomic batch with problems leaves surfaces as they were', () {
    final ui = UiSurfaces(basicCatalog)..applyAll([formSurface]);
    final surface = ui.surfaces['signup']!;
    final problems = ui.applyAll([
      envelope('updateDataModel', {
        'surfaceId': 'signup',
        'path': '/x',
        'value': 1,
      }),
      dangling,
      envelope('createSurface', {'surfaceId': 'extra'}),
    ], atomic: true);
    expect(problems, isNotEmpty);
    expect(ui.surfaces.keys, ['signup']);
    expect(identical(ui.surfaces['signup'], surface), isTrue);
    expect(surface.root!.type, 'Column');
    expect(surface.data.read('/x'), isNull);
  });

  test('a deleted surface comes back when the batch fails', () {
    final ui = UiSurfaces(basicCatalog)
      ..applyAll([formSurface])
      ..applyAll([
        envelope('deleteSurface', {'surfaceId': 'signup'}),
        envelope('deleteSurface', {'surfaceId': 'missing'}),
      ], atomic: true);
    expect(ui.surfaces['signup']!.components, hasLength(4));
  });

  test('a clean atomic batch applies, and a plain one keeps partial work', () {
    final ui = UiSurfaces(basicCatalog);
    expect(ui.applyAll([formSurface], atomic: true), isEmpty);
    expect(ui.applyAll([dangling]), isNotEmpty);
    expect(ui.surfaces['signup']!.root!.type, 'Card');
  });

  test('a tool call with problems changes nothing', () async {
    final surfaces = UiSurfaces(basicCatalog)..applyAll([formSurface]);
    final result = await uiTool(surfaces, format: UiFormat.messages).invoke(
      ToolCallPart(
        id: 'c',
        name: 'render_ui',
        arguments: {
          'messages': [dangling],
        },
      ),
    );
    expect((result.output! as Map)['shown'], isEmpty);
    expect(surfaces.surfaces['signup']!.root!.type, 'Column');
  });

  test('creating an existing surface can replace it', () {
    final ui = UiSurfaces(basicCatalog)..applyAll([formSurface]);
    final again = envelope('createSurface', {
      'surfaceId': 'signup',
      'components': [
        {'id': 'root', 'component': 'Divider'},
      ],
    });
    expect(ui.applyAll([again]).single.message, contains('already a surface'));
    expect(ui.applyAll([again], replace: true), isEmpty);
    expect(ui.surfaces['signup']!.components.keys, ['root']);
    final invalid = envelope('createSurface', {
      'surfaceId': 'signup',
      'components': 3,
    });
    expect(ui.applyAll([invalid], replace: true), isNotEmpty);
    expect(ui.surfaces['signup']!.components.keys, ['root']);
  });
}
