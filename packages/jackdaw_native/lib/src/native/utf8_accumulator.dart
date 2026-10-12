import 'dart:convert';

/// Turns byte chunks that may split a UTF-8 character into whole strings.
final class Utf8Accumulator {
  /// Creates an empty accumulator.
  factory() = Utf8Accumulator._;

  new _();

  final List<int> _pending = [];

  /// Adds [bytes] and returns the text of every complete character so far.
  String add(List<int> bytes) {
    _pending.addAll(bytes);
    final end = _completeLength();
    final text = utf8.decode(_pending.sublist(0, end), allowMalformed: true);
    _pending.removeRange(0, end);
    return text;
  }

  /// Returns what is left, replacing an unfinished character.
  String flush() {
    final text = utf8.decode(_pending, allowMalformed: true);
    _pending.clear();
    return text;
  }

  int _completeLength() {
    final length = _pending.length;
    for (var back = 1; back <= 3 && back <= length; back++) {
      final byte = _pending[length - back];
      if (byte & 0xC0 == 0x80) continue;
      final needed = switch (byte) {
        >= 0xF0 => 4,
        >= 0xE0 => 3,
        >= 0xC0 => 2,
        _ => 1,
      };
      return needed > back ? length - back : length;
    }
    return length;
  }
}
