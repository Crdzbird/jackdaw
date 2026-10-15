import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  final scope = UiScope(UiDataModel());
  final ui = UiEvaluator(basicCatalog);
  Object? call(String name, Map<String, Object?> args) =>
      ui.evaluate({'@call': name, 'args': args}, scope);
  bool passes(String name, Map<String, Object?> args) =>
      uiTruth(call(name, args));

  test('checks return validation results', () {
    expect(call('required', {'value': 'x'}), {'valid': true});
    for (final empty in [null, '', <Object?>[]]) {
      expect(passes('required', {'value': empty}), isFalse);
    }
    expect(passes('required', {'value': 0}), isTrue);
    expect(passes('regex', {'value': 'abc', 'pattern': '^a'}), isTrue);
    expect(passes('regex', {'value': 'abc', 'pattern': '('}), isFalse);
    expect(passes('length', {'value': 'abc', 'min': 2, 'max': 3}), isTrue);
    expect(passes('length', {'value': 'abcd', 'max': 3}), isFalse);
    expect(passes('numeric', {'value': '5', 'min': 1, 'max': 9}), isTrue);
    expect(passes('numeric', {'value': 10, 'max': 9}), isFalse);
    expect(passes('numeric', {'value': 'many'}), isFalse);
    expect(passes('email', {'value': 'a@b.co'}), isTrue);
    expect(passes('email', {'value': 'a@b'}), isFalse);
  });

  test('numbers and money are written in English', () {
    expect(call('formatNumber', {'value': 1234567.891}), '1,234,567.891');
    expect(call('formatNumber', {'value': 1234.5, 'decimals': 2}), '1,234.50');
    expect(call('formatNumber', {'value': 1234, 'grouping': false}), '1234');
    expect(call('formatNumber', {'value': -0.001, 'decimals': 2}), '0.00');
    expect(call('formatNumber', {'value': '42'}), '42');
    expect(
      call('formatCurrency', {'value': 1500, 'currency': 'usd'}),
      r'$1,500.00',
    );
    expect(
      call('formatCurrency', {'value': -3, 'currency': 'EUR'}),
      '-\u20AC3.00',
    );
    expect(
      call('formatCurrency', {'value': 900, 'currency': 'JPY'}),
      '\u00A5900',
    );
    expect(
      call('formatCurrency', {'value': 1, 'currency': 'CHF'}),
      'CHF\u00A01.00',
    );
    expect(
      () => call('formatNumber', {'value': 'lots'}),
      throwsA(isA<UiEvalException>()),
    );
  });

  test('plurals and logic', () {
    final plural = {'one': 'item', 'other': 'items'};
    expect(call('pluralize', {'value': 1, ...plural}), 'item');
    expect(call('pluralize', {'value': 0, ...plural}), 'items');
    expect(call('pluralize', {'value': 1, 'other': 'x'}), 'x');
    expect(
      call('and', {
        'values': [
          true,
          {'valid': true},
        ],
      }),
      isTrue,
    );
    expect(
      call('and', {
        'values': [true, false],
      }),
      isFalse,
    );
    expect(
      call('or', {
        'values': [
          false,
          {'valid': true},
        ],
      }),
      isTrue,
    );
    expect(call('or', {'values': 'nope'}), isFalse);
    expect(call('not', {'value': false}), isTrue);
  });
}
