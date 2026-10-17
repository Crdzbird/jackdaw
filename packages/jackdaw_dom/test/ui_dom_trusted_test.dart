@TestOn('browser')
library;

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_dom/jackdaw_dom.dart';
import 'package:test/test.dart';

void main() {
  test('a trusted screen is applied without its checks', () {
    final ui = UiDomController(basicCatalog);
    final problems = ui.applyAll([
      {
        'version': 'v1.0',
        'createSurface': {
          'surfaceId': 's',
          'components': [
            {'id': 'root', 'component': 'Text'},
          ],
        },
      },
    ], trusted: true);
    expect(problems, isEmpty);
    expect(ui.surfaces.surfaces['s'], isNotNull);
  });
}
