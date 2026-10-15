import 'package:flutter_test/flutter_test.dart';

import 'support/show_surface.dart';

Map<String, Object?> picker(Map<String, Object?> props) =>
    c('root', 'DateTimeInput', {
      'label': 'When',
      'value': {'@path': '/when'},
      ...props,
    });

void main() {
  testWidgets('a date is picked and written as an ISO date', (tester) async {
    final controller = await showSurface(
      tester,
      [
        picker({'enableDate': true, 'min': '2026-01-01', 'max': '2026-12-31'}),
      ],
      data: {'when': '2026-01-16'},
    );
    expect(find.text('2026-01-16'), findsOneWidget);
    await tester.tap(find.text('When'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(dataAt(controller, '/when'), '2026-01-20');
  });

  testWidgets('a time, or a date and a time, is picked', (tester) async {
    final time = await showSurface(
      tester,
      [
        picker({'enableTime': true}),
      ],
      data: {'when': '2026-01-16T09:30:00'},
    );
    await tester.tap(find.text('When'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(dataAt(time, '/when'), '09:30');
    final both = await showSurface(
      tester,
      [
        picker({'enableDate': true, 'enableTime': true}),
      ],
      data: {'when': '2026-01-16T09:30:00'},
    );
    await tester.tap(find.text('When'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(dataAt(both, '/when'), '2026-01-16T09:30:00');
  });

  testWidgets('cancelling leaves the value alone', (tester) async {
    final empty = await showSurface(tester, [picker({})]);
    expect(find.text('Not set'), findsOneWidget);
    await tester.tap(find.text('When'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(dataAt(empty, '/when'), isNull);
    final timeOnly = await showSurface(tester, [
      picker({'enableTime': true}),
    ]);
    await tester.tap(find.text('When'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(dataAt(timeOnly, '/when'), isNull);
    await showSurface(tester, [
      c('root', 'DateTimeInput', {'value': ''}),
    ]);
    expect(find.text('Date'), findsOneWidget);
  });
}
