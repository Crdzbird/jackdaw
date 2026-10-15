import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  final data = UiDataModel({
    'user': {
      'name': 'Ana',
      'age': 30,
      'tags': ['a'],
    },
    'date': '2026-01-16T09:00:00Z',
    'list': [
      {'title': 'first'},
    ],
  });
  final ui = UiEvaluator(basicCatalog);
  String format(String template, [UiScope? scope]) =>
      ui.evaluate({
            '@call': 'formatString',
            'args': {'value': template},
          }, scope ?? UiScope(data))!
          as String;

  test('placeholders read paths, literals and calls', () {
    expect(format(r'Hi ${/user/name}, ${/user/age}!'), 'Hi Ana, 30!');
    expect(format(r'${title}', UiScope(data).item('/list', 0)), 'first');
    expect(format(r"${'quoted'} ${2.0} ${-3} ${true}"), 'quoted 2 -3 true');
    expect(format(r'${"double"}'), 'double');
    expect(
      format(r'[${null}] ${false} ${/user/tags} ${/missing}'),
      '[] false ["a"] ',
    );
    expect(format(r'${/user}'), '{"name":"Ana","age":30,"tags":["a"]}');
    expect(
      format(r"On ${formatDate(value: ${/date}, format: 'MMM d')}"),
      'On Jan 16',
    );
    expect(format(r'${formatNumber(value: 1234 , grouping: false)}'), '1234');
    expect(format(r'${not(value: false)}'), 'true');
    expect(format(r'${formatString()}'), '');
  });

  test('escaped markers stay literal', () {
    expect(format(r'Price \${x} ${/user/age}'), r'Price ${x} 30');
    expect(format('no placeholders'), 'no placeholders');
  });

  test('malformed placeholders are expression errors', () {
    final error = throwsA(
      isA<UiEvalException>().having((e) => e.code, 'code', 'EXPRESSION_ERROR'),
    );
    for (final bad in [
      r'${/user/name',
      r'${}',
      r"${'open}",
      r'${not(value false)}',
      r'${not(: 1)}',
      r'${not(value: 1',
      r'${shout()}',
    ]) {
      expect(() => format(bad), error, reason: bad);
    }
  });
}
