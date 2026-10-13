import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

void main() {
  testWidgets('pieces arriving in one frame notify once', (tester) async {
    final text = FrameText();
    var notified = 0;
    text.addListener(() => notified++);
    for (var i = 0; i < 50; i++) {
      text.append('a');
    }
    expect(text.value, isEmpty);
    await tester.pump();
    expect(text.value, 'a' * 50);
    expect(notified, 1);
    text
      ..append('b')
      ..clear();
    await tester.pump();
    expect(text.value, isEmpty);
    text
      ..append('c')
      ..dispose();
    await tester.pump();
  });
}
