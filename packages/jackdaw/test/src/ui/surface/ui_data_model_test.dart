import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('values are read and written by pointer', () {
    final data = UiDataModel({
      'user': {'name': 'Ana'},
      'tags': ['a', 'b'],
    });
    expect(data.read('/user/name'), 'Ana');
    expect(data.read('/tags/1'), 'b');
    expect(data.read('/tags/9'), isNull);
    expect(data.read('/tags/x'), isNull);
    expect(data.read('/user/name/deeper'), isNull);
    data
      ..write('/user/age', 30)
      ..write('/form/email', 'a@b.c')
      ..write('/tags/0', 'z')
      ..write('/tags/-', 'c')
      ..write('/tags/1', null)
      ..write('/tags/7', 'ignored')
      ..write('/user/name', null);
    expect(data.root, {
      'user': {'age': 30},
      'tags': ['z', 'c'],
      'form': {'email': 'a@b.c'},
    });
  });

  test('the root can be replaced or cleared', () {
    final data = UiDataModel()..write('/', ['x']);
    expect(data.root, ['x']);
    data.write('/0/name', 'n');
    expect(data.root, [
      {'name': 'n'},
    ]);
    data.write('', null);
    expect(data.root, <String, Object?>{});
    final scalar = UiDataModel()
      ..write('/', 3)
      ..write('/a', 1);
    expect(scalar.root, {'a': 1});
  });

  test('written values are copied', () {
    const source = {
      'list': [1],
    };
    final data = UiDataModel(source)..write('/list/-', 2);
    expect(data.read('/list'), [1, 2]);
    expect(source['list'], [1]);
  });
}
