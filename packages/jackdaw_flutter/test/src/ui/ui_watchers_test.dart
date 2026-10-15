import 'package:flutter_test/flutter_test.dart';
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
}
