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
