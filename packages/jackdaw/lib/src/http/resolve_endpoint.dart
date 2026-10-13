/// Resolves [path] against [root], treating [root] as a directory even when
/// it lacks a trailing slash, so `http://host/v1` and `http://host/v1/`
/// both lead to `http://host/v1/<path>`.
Uri resolveEndpoint(Uri root, String path) {
  final base = root.path.endsWith('/')
      ? root
      : root.replace(path: '${root.path}/');
  return base.resolve(path);
}
