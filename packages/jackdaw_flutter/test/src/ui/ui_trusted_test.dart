import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

void main() {
  test('a trusted screen is applied without its checks', () {
    final controller = UiSurfaceController(basicCatalog);
    final problems = controller.applyAll([
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
    expect(controller.surfaces.surfaces['s'], isNotNull);
    controller.dispose();
  });
}
