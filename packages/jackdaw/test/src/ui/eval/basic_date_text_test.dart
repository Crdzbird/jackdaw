import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  final scope = UiScope(UiDataModel());
  final ui = UiEvaluator(basicCatalog);
  Object? call(String name, Map<String, Object?> args) =>
      ui.evaluate({'@call': name, 'args': args}, scope);

  test('dates follow TR35 patterns', () {
    const date = '2026-01-16T09:05:03Z';
    expect(
      call('formatDate', {'value': date, 'format': 'MMM dd, yyyy'}),
      'Jan 16, 2026',
    );
    expect(
      call('formatDate', {'value': date, 'format': 'EEEE d MMMM yy'}),
      'Friday 16 January 26',
    );
    expect(
      call('formatDate', {
        'value': date,
        'format': "h:mm:ss a 'o''clock' E M/d",
      }),
      "9:05:03 AM o'clock Fri 1/16",
    );
    expect(
      call('formatDate', {'value': 0, 'format': 'HH:mm yyyy'}),
      '00:00 1970',
    );
    expect(
      call('formatDate', {'value': '2026-01-16T15:00:00Z', 'format': 'hh a'}),
      '03 PM',
    );
    expect(
      call('formatDate', {'value': '2026-01-16T00:00:00Z', 'format': 'h'}),
      '12',
    );
    expect(
      () => call('formatDate', {'value': 'soon', 'format': 'yyyy'}),
      throwsA(isA<UiEvalException>()),
    );
  });
}
