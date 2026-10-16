import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

void main() {
  test('a removed write listener hears nothing more', () {
    final changes = UiChanges();
    var heard = 0;
    void listener(String surfaceId, String pointer) => heard++;
    changes
      ..addWriteListener(listener)
      ..wrote('s', '/a')
      ..removeWriteListener(listener)
      ..wrote('s', '/a');
    expect(heard, 1);
    changes.dispose();
  });

  test('a disposed controller frees its change notifier', () {
    final controller = UiSurfaceController(basicCatalog)..dispose();
    expect(() => controller.changes.addListener(() {}), throwsFlutterError);
  });
}
