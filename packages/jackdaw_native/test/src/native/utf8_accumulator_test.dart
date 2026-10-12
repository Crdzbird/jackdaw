import 'dart:convert';

import 'package:jackdaw_native/src/native/utf8_accumulator.dart';
import 'package:test/test.dart';

void main() {
  test('holds back characters split across chunks', () {
    final bytes = utf8.encode('a\u{e9}\u{20ac}\u{1f426}');
    final text = Utf8Accumulator();
    final out = [
      for (final byte in bytes) text.add([byte]),
    ].join();
    expect(out + text.flush(), 'a\u{e9}\u{20ac}\u{1f426}');
  });

  test('flush replaces an unfinished character', () {
    final text = Utf8Accumulator();
    expect(text.add([0x61, 0xE2, 0x82]), 'a');
    expect(text.flush(), '\u{fffd}');
    expect(text.add(const []), '');
  });

  test('passes stray continuation bytes through', () {
    expect(Utf8Accumulator().add([0x80, 0x80, 0x80, 0x80]), isNotEmpty);
  });
}
