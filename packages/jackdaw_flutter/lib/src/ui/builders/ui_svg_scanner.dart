final RegExp _number = RegExp(r'[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?');

final RegExp _letter = RegExp('[A-Za-z]');

/// Reads the tokens of SVG path data: command letters, numbers and the
/// one-digit flags of arcs, skipping spaces and commas. Malformed data
/// throws a [FormatException].
final class UiSvgScanner {
  /// Creates a scanner of [data].
  factory(String data) = UiSvgScanner._;

  new _(this.data);

  /// The path data.
  final String data;

  int _at = 0;

  /// Whether only spaces and commas are left.
  bool get done => _skip() >= data.length;

  /// The next command letter, consumed, or `null` when a number is next.
  String? letter() {
    final at = _skip();
    if (!_letter.hasMatch(data[at])) return null;
    _at = at + 1;
    return data[at];
  }

  /// The next number.
  double number() {
    final match = _number.matchAsPrefix(data, _skip());
    if (match == null) throw const FormatException('expected a number');
    _at = match.end;
    return double.parse(match[0]!);
  }

  /// The next arc flag, a single 0 or 1.
  bool flag() {
    final at = _skip();
    if (at >= data.length || !'01'.contains(data[at])) {
      throw const FormatException('expected a flag');
    }
    _at = at + 1;
    return data[at] == '1';
  }

  int _skip() {
    while (_at < data.length &&
        (data[_at] == ',' || data[_at].trim().isEmpty)) {
      _at++;
    }
    return _at;
  }
}
