import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import '../ui_fixtures.dart';

Map<String, Object?> envelope(String kind, Map<String, Object?> body) => {
  'version': 'v1.0',
  kind: body,
};

void main() {
  test('a valid surface is built with its components and data', () {
    final ui = UiSurfaces(basicCatalog);
    expect(ui.applyAll([formSurface]), isEmpty);
    final surface = ui.surfaces['signup']!;
    expect(surface.root!.type, 'Column');
    expect(surface.components.keys, ['root', 'email', 'send', 'sendLabel']);
    expect(surface.data.read('/form/email'), '');
    expect(surface.components['email']!.toJson()['label'], 'Email');
  });

  test('updates, data writes and deletes apply in order', () {
    final ui = UiSurfaces(basicCatalog);
    final problems = ui.applyAll([
      envelope('createSurface', {'surfaceId': 'birds'}),
      ...listMessages.take(2),
    ]);
    expect(problems, isEmpty);
    expect(ui.surfaces['birds']!.data.read('/birds'), <Object?>[]);
    expect(ui.applyAll([listMessages.last]), isEmpty);
    expect(ui.surfaces, isEmpty);
  });

  test('messages that break the protocol change nothing', () {
    final ui = UiSurfaces(basicCatalog);
    final invalid = ui.apply(envelope('deleteSurface', {'surfaceId': 1}));
    expect(invalid.single.code, UiProblemCode.validationFailed);
    expect(invalid.single.path, '/deleteSurface/surfaceId');
    final missing = ui.apply(envelope('deleteSurface', {'surfaceId': 'x'}));
    expect(missing.single.message, 'There is no surface x.');
    ui.apply(envelope('createSurface', {'surfaceId': 'x'}));
    final twice = ui.apply(envelope('createSurface', {'surfaceId': 'x'}));
    expect(twice.single.message, 'There is already a surface x.');
    expect(twice.single.toJson(), {
      'version': 'v1.0',
      'error': {
        'code': 'VALIDATION_FAILED',
        'surfaceId': 'x',
        'path': '/createSurface/surfaceId',
        'message': 'There is already a surface x.',
      },
    });
  });

  test('repeated ids and broken trees are reported', () {
    final ui = UiSurfaces(basicCatalog);
    final problems = ui.applyAll([
      envelope('createSurface', {
        'surfaceId': 's',
        'components': [
          {'id': 'root', 'component': 'Card', 'child': 'gone'},
          {'id': 'a', 'component': 'Text', 'text': 'x'},
          {'id': 'a', 'component': 'Text', 'text': 'y'},
        ],
      }),
    ]);
    const repeated =
        '/createSurface/components/2/id '
        'The id a is used by more than one component.';
    expect(problems.map((p) => '${p.path} ${p.message}'), [
      repeated,
      '/components/root/child There is no component with the id gone.',
      '/components/a The component a is not reachable from root, so it is not shown.',
    ]);
    expect('${problems.first}', startsWith('VALIDATION_FAILED s /create'));
  });
}
