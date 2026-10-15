/// The reference tokens of the JSON Pointer [pointer], unescaped.
///
/// An empty pointer and `/` both name the whole document.
List<String> jsonPointerTokens(String pointer) => [
  for (final token in pointer.split('/').skip(1))
    if (token.isNotEmpty) token.replaceAll('~1', '/').replaceAll('~0', '~'),
];

/// [tokens] written as a JSON Pointer, escaped.
String jsonPointer(Iterable<Object> tokens) => [
  for (final token in tokens)
    '/${'$token'.replaceAll('~', '~0').replaceAll('/', '~1')}',
].join();

/// [path] resolved against the pointer [scope]: an absolute path stays as
/// it is and a relative one is appended to the scope.
String resolveJsonPointer(String path, String scope) {
  if (path.startsWith('/')) return path;
  final base = scope.endsWith('/') ? scope : '$scope/';
  return '$base$path';
}

/// The JSON Pointer for a schema violation path such as `$.a[0].b`.
String violationPointer(String path) => jsonPointer([
  for (final match in RegExp(r'\.([^.\[]+)|\[(\d+)\]').allMatches(path))
    match.group(1) ?? match.group(2)!,
]);
