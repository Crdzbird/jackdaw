import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_rule.dart';

import 'support/rule_frame.dart';

void main() {
  testWidgets('follows a change of theme', (tester) async {
    await tester.pumpWidget(ruleFrame(const UiRule(), material3: true));
    expect(tester.getSize(find.byType(UiRule)).height, 16);
    await tester.pumpWidget(
      ruleFrame(
        const UiRule(),
        material3: true,
        theme: const DividerThemeData(space: 30),
      ),
    );
    await tester.pumpAndSettle();
    final box = tester.renderObject<RenderBox>(find.byType(UiRule));
    expect(box.size.height, 30);
    expect(box.getMinIntrinsicHeight(100), 30);
    expect(box.getMaxIntrinsicHeight(100), 30);
  });

  testWidgets('indents from the start in right to left text', (tester) async {
    const theme = DividerThemeData(
      thickness: 2,
      space: 10,
      indent: 4,
      endIndent: 6,
    );
    await tester.pumpWidget(
      ruleFrame(
        const UiRule(),
        material3: true,
        theme: theme,
        direction: TextDirection.rtl,
      ),
    );
    expect(
      tester.renderObject(find.byType(UiRule)),
      paints..rect(rect: const Rect.fromLTWH(6, 4, 190, 2)),
    );
  });

  testWidgets('paints nothing when the indents fill it', (tester) async {
    const theme = DividerThemeData(indent: 120, endIndent: 120);
    await tester.pumpWidget(
      ruleFrame(const UiRule(), material3: true, theme: theme),
    );
    expect(tester.renderObject(find.byType(UiRule)), paintsNothing);
  });
}
