import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_svg_path_reader.dart';

void main() {
  test('every SVG command is read, absolute and relative', () {
    final path = UiSvgPathReader(
      'M2 2 L10 2 H12 V4 h1 v1 l1 1 C14 6 15 7 16 8 S18 10 19 11 '
      'c1 1 2 2 3 3 s1 1 1 1 Q20 20 21 21 T22 22 q1 1 0 1 t-1 0 '
      'A2 2 0 0 1 4 22 a1 1 0 1 0 1 1 Z m1 1 2 2 z',
    ).read();
    expect(path, isNotNull);
    final bounds = path!.getBounds();
    expect(bounds.left, lessThanOrEqualTo(2));
    expect(bounds.right, greaterThanOrEqualTo(22));
  });

  test('compact numbers and flags are separated', () {
    expect(UiSvgPathReader('M0,0a1,1,0,001,1').read(), isNotNull);
    expect(UiSvgPathReader('M.5.5l-1e1-1').read(), isNotNull);
  });

  test('malformed data gives no path', () {
    for (final bad in [
      'M0',
      'X1 1',
      '1 1',
      'M0 0 A1 1 0 2 0 1 1',
      'M0 0 A1 1 0 0',
    ]) {
      expect(UiSvgPathReader(bad).read(), isNull, reason: bad);
    }
  });
}
