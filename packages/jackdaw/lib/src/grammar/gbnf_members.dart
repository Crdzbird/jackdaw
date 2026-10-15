/// The GBNF body of a JSON object whose members are given in order as
/// `(member, required)` pairs, where each member is the expression for one
/// `"key": value` pair.
///
/// Required members are always emitted and optional ones may be left out,
/// so the grammar accepts exactly the member lists the schema allows in
/// declaration order. Members are separated by commas with bounded
/// whitespace.
String gbnfObjectBody(List<(String, bool)> members) {
  if (members.isEmpty) return '"{" ws "}"';
  final first = _first(members, 0);
  final optional = members.every((member) => !member.$2);
  return '"{" ws ${optional ? '($first)?' : first} ws "}"';
}

String _first(List<(String, bool)> members, int index) {
  final (member, required) = members[index];
  final head = [
    member,
    for (final (next, mandatory) in members.skip(index + 1))
      '(ws "," ws $next)${mandatory ? '' : '?'}',
  ].join(' ');
  if (required || index == members.length - 1) return head;
  return '($head | ${_first(members, index + 1)})';
}

/// The largest repetition count a grammar spells out.
///
/// llama.cpp writes out a rule for every optional repetition, so larger
/// bounds are left to validation, which still enforces them, instead of
/// costing thousands of rules.
const int gbnfMaxRepeat = 64;

/// The GBNF body of a JSON list between [open] and [close] that starts
/// with one element matching each rule of [prefix], in order, followed by
/// elements matching [item], at least [min] and at most [max] in all, as
/// far as [gbnfMaxRepeat] allows.
String gbnfRepeat(
  String open,
  String item,
  String close, {
  int min = 0,
  int? max,
  List<String> prefix = const [],
}) {
  if (max != null && (max < min || max < 1)) {
    throw ArgumentError.value(max, 'max', 'must be at least 1 and min');
  }
  if (min < prefix.length) {
    throw ArgumentError.value(min, 'min', 'must cover the prefix items');
  }
  final more = '(ws "," ws $item)';
  if (prefix.isEmpty) {
    final items = [
      item,
      _times(more, min < 1 ? 0 : min - 1, _less(max, 1)),
    ].where((part) => part.isNotEmpty).join(' ');
    return '$open ws ${min == 0 ? '($items)?' : items} ws $close';
  }
  final rest = _times(more, min - prefix.length, _less(max, prefix.length));
  final items = [
    prefix.join(' ws "," ws '),
    rest,
  ].where((part) => part.isNotEmpty).join(' ');
  return '$open ws $items ws $close';
}

int? _less(int? max, int count) => max == null ? null : max - count;

String _times(String more, int low, int? high) => switch ((
  low < gbnfMaxRepeat ? low : gbnfMaxRepeat,
  high == null || high > gbnfMaxRepeat ? null : high,
)) {
  (_, 0) => '',
  (0, null) => '$more*',
  (final from, null) => '$more{$from,}',
  (final from, final int top) => '$more{$from,$top}',
};
