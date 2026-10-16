import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_rule.dart';

import 'support/rule_frame.dart';

void main() {
  for (final material3 in [true, false]) {
    testWidgets('takes the space of a Divider, Material 3 is $material3', (
      tester,
    ) async {
      await tester.pumpWidget(ruleFrame(const Divider(), material3: material3));
      final divider = tester.getSize(find.byType(Divider));
      await tester.pumpWidget(ruleFrame(const UiRule(), material3: material3));
      expect(tester.getSize(find.byType(UiRule)), divider);
    });
  }

  testWidgets('paints the line with the divider theme', (tester) async {
    const theme = DividerThemeData(
      color: Color(0xFFFF0000),
      thickness: 2,
      space: 10,
      indent: 4,
      endIndent: 6,
    );
    await tester.pumpWidget(
      ruleFrame(const UiRule(), material3: true, theme: theme),
    );
    expect(tester.getSize(find.byType(UiRule)), const Size(200, 10));
    expect(
      tester.renderObject(find.byType(UiRule)),
      paints..rect(
        rect: const Rect.fromLTWH(4, 4, 190, 2),
        color: const Color(0xFFFF0000),
      ),
    );
  });

  testWidgets('draws a hairline in Material 2', (tester) async {
    await tester.pumpWidget(ruleFrame(const UiRule(), material3: false));
    expect(tester.renderObject(find.byType(UiRule)), paints..line());
  });
}
