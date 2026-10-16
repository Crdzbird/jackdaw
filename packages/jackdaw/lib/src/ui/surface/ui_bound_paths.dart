import 'package:jackdaw/jackdaw.dart';

/// The data pointers [props] read in a scope at [scope]: every `@path`
/// binding, in calls too, and the list of a template. A string with a
/// `${...}` part, as `formatString` takes, may read anywhere, so it makes
/// the whole data model, `/`, a dependency.
Set<String> uiBoundPaths(Object? props, String scope) {
  final paths = <String>{};
  void walk(Object? value) {
    switch (value) {
      case {'@path': final String path}:
        paths.add(resolveJsonPointer(path, scope));
      case {'componentId': final String _, 'path': final String path}:
        paths.add(resolveJsonPointer(path, scope));
      case final Map<String, Object?> map:
        map.values.forEach(walk);
      case final List<Object?> list:
        list.forEach(walk);
      case final String text when text.contains(r'${'):
        paths.add('/');
    }
  }

  walk(props);
  return paths;
}
