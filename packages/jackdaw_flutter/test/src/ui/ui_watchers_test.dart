import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';
import 'package:jackdaw_flutter/src/ui/ui_watchers.dart';

void main() {
  test('a write reaches its path, the paths around it and the root', () {
    final heard = <String>[];
    final watchers = UiWatchers();
    for (final path in ['/a', '/a/b', '/ab', '/']) {
      watchers.add({path}, () => heard.add(path));
    }
    List<String> after(String pointer) {
      heard.clear();
      watchers.wrote(pointer);
      return [...heard]..sort();
    }

    expect(after('/a'), ['/', '/a', '/a/b']);
    expect(after('/a/b/c'), ['/', '/a', '/a/b']);
    expect(after('/ab'), ['/', '/ab']);
    expect(after('/'), ['/', '/a', '/a/b', '/ab']);
    expect(watchers.remove({'/a'}, () {}), isFalse);
  });

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
