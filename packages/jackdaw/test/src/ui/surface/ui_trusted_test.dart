import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  final message = {
    'version': 'v1.0',
    'createSurface': {
      'surfaceId': 's',
      'components': [
        {
          'id': 'root',
          'component': 'Column',
          'children': ['gone'],
        },
        {'id': 'loose', 'component': 'Text'},
      ],
    },
  };

  test('an untrusted message is checked and kept out', () {
    final surfaces = UiSurfaces(basicCatalog);
    final problems = surfaces.applyAll([message], atomic: true);
    expect(problems.where((p) => !p.warning), isNotEmpty);
    expect(surfaces.surfaces, isEmpty);
  });

  test('a trusted message is applied as it is, without checks', () {
    final surfaces = UiSurfaces(basicCatalog);
    final problems = surfaces.applyAll([message], atomic: true, trusted: true);
    expect(problems, isEmpty);
    expect(surfaces.surfaces['s']!.components.keys, ['root', 'loose']);
  });
}
