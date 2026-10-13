import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

void main() {
  testWidgets('paragraphs become separate texts and blanks are skipped', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Paragraphs('One.\n\nTwo\nlines.\n\n\n\nThree.')),
    );
    expect(find.byType(Text), findsNWidgets(3));
    expect(find.text('Two\nlines.'), findsOneWidget);
  });
}
