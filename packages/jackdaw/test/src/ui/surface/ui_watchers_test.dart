import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

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

  test('a removed watcher hears nothing, and the last one leaves none', () {
    var heard = 0;
    void onWrite() => heard++;
    final watchers = UiWatchers()..add({'/a', '/a/b'}, onWrite);
    expect(watchers.remove({'/a', '/a/b'}, onWrite), isTrue);
    watchers.wrote('/a');
    expect(heard, 0);
  });
}
