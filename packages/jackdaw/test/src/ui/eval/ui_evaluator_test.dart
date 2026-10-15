import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  final data = UiDataModel({
    'user': {'name': 'Ana'},
    'items': [
      {'title': 'first'},
      {'title': 'second'},
    ],
  });
  final scope = UiScope(data);
  final ui = UiEvaluator(basicCatalog);

  test('literals, bindings and escaped keys', () {
    expect(ui.evaluate('x', scope), 'x');
    expect(ui.evaluate({'@path': '/user/name'}, scope), 'Ana');
    expect(ui.evaluate({'@path': '/missing'}, scope), isNull);
    expect(
      ui.evaluate([
        {'@path': '/user/name'},
        1,
      ], scope),
      ['Ana', 1],
    );
    expect(ui.evaluate({'@@path': 'kept', 'n': 1}, scope), {
      '@path': 'kept',
      'n': 1,
    });
  });

  test('relative paths and @index follow the list item', () {
    final item = scope.item('/items', 1);
    expect(item.path, '/items/1');
    expect(ui.evaluate({'@path': 'title'}, item), 'second');
    expect(ui.evaluate({'@call': '@index'}, item), 1);
    expect(
      ui.evaluate({
        '@call': '@index',
        'args': {'offset': 1},
      }, item),
      2,
    );
    expect(
      () => ui.evaluate({'@call': '@index'}, scope),
      throwsA(
        isA<UiEvalException>().having((e) => e.code, 'code', 'EXECUTION_ERROR'),
      ),
    );
  });

  test('calls run catalog functions with resolved arguments', () {
    expect(
      ui.evaluate({
        '@call': 'formatString',
        'args': {'value': r'Hi ${/user/name}'},
      }, scope),
      'Hi Ana',
    );
    expect(
      ui.truth({
        '@call': 'required',
        'args': {
          'value': {'@path': '/user/name'},
        },
      }, scope),
      isTrue,
    );
    expect(
      ui.truth({
        '@call': 'required',
        'args': {
          'value': {'@path': '/none'},
        },
      }, scope),
      isFalse,
    );
  });
}
