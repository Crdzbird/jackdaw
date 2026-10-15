import 'package:jackdaw/src/ui/eval/ui_eval_exception.dart';

final List<String> _months =
    'January February March April May June July August September October '
            'November December'
        .split(' ');

final List<String> _days =
    'Monday Tuesday Wednesday Thursday Friday Saturday Sunday'.split(' ');

final RegExp _token = RegExp(r"'([^']|'')*'|([A-Za-z])\2*|.", dotAll: true);

/// [value], an ISO 8601 date or milliseconds since the epoch, written with
/// the Unicode TR35 [pattern] in English: `yyyy`, `yy`, `M` to `MMMM`, `d`,
/// `dd`, `E` to `EEEE`, `H`, `HH`, `h`, `hh`, `mm`, `ss` and `a`, with text
/// in single quotes kept as it is.
String basicDateText(Object? value, String pattern) {
  final date = switch (value) {
    final DateTime d => d,
    final num n => DateTime.fromMillisecondsSinceEpoch(n.toInt(), isUtc: true),
    final String s => DateTime.tryParse(s),
    _ => null,
  };
  if (date == null) {
    throw const UiEvalException('EXECUTION_ERROR', 'formatDate needs a date.');
  }
  return [
    for (final match in _token.allMatches(pattern)) _field(date, match[0]!),
  ].join();
}

String _field(DateTime date, String token) {
  String pad(int n) => '$n'.padLeft(token.length, '0');
  final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
  return switch (token[0]) {
    "'" when token.length > 1 =>
      token.substring(1, token.length - 1).replaceAll("''", "'"),
    'y' when token.length == 2 => '${date.year % 100}'.padLeft(2, '0'),
    'y' => pad(date.year),
    'M' when token.length >= 4 => _months[date.month - 1],
    'M' when token.length == 3 => _months[date.month - 1].substring(0, 3),
    'M' => pad(date.month),
    'd' => pad(date.day),
    'E' when token.length >= 4 => _days[date.weekday - 1],
    'E' => _days[date.weekday - 1].substring(0, 3),
    'H' => pad(date.hour),
    'h' => pad(hour12),
    'm' => pad(date.minute),
    's' => pad(date.second),
    'a' => date.hour < 12 ? 'AM' : 'PM',
    _ => token,
  };
}
