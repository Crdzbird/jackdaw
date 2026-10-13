/// [text] on one line, cut to [limit] characters with an ellipsis of dots.
String clip(String text, [int limit = 100]) {
  final line = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return line.length <= limit ? line : '${line.substring(0, limit - 3)}...';
}
