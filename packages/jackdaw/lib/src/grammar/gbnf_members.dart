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

/// The GBNF body of a JSON list between [open] and [close] of at least
/// [min] and at most [max] elements matching [item], separated by commas.
String gbnfRepeat(
  String open,
  String item,
  String close, [
  int min = 0,
  int? max,
]) {
  if (max != null && (max < min || max < 1)) {
    throw ArgumentError.value(max, 'max', 'must be at least 1 and min');
  }
  final more = '(ws "," ws $item)';
  final first = min < 1 ? 0 : min - 1;
  final rest = switch ((first, max)) {
    (0, null) => '$more*',
    (_, null) => '$more{$first,}',
    (_, final int top) => '$more{$first,${top - 1}}',
  };
  final items = '$item $rest';
  return '$open ws ${min == 0 ? '($items)?' : items} ws $close';
}
