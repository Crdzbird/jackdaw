import 'package:flutter/foundation.dart';

String _key(String path) => path == '/' ? '' : path;

/// The callbacks watching data paths of one surface, indexed by path, so
/// a write reaches its own path, its ancestors and the root by lookup,
/// and scans for paths below it only when some are watched there.
final class UiWatchers {
  final Map<String, Set<VoidCallback>> _byPath = {};
  final Map<String, int> _below = {};

  /// Watches [paths] with [onWrite].
  void add(Set<String> paths, VoidCallback onWrite) {
    for (final path in paths.map(_key)) {
      if ((_byPath[path] ??= {}).add(onWrite)) _count(path, 1);
    }
  }

  /// Stops [onWrite] watching [paths]; returns whether none are left.
  bool remove(Set<String> paths, VoidCallback onWrite) {
    for (final path in paths.map(_key)) {
      final set = _byPath[path];
      if (set == null || !set.remove(onWrite)) continue;
      _count(path, -1);
      if (set.isEmpty) _byPath.remove(path);
    }
    return _byPath.isEmpty;
  }

  void _count(String path, int by) {
    for (var at = path; at.isNotEmpty;) {
      at = at.substring(0, at.lastIndexOf('/'));
      _below[at] = (_below[at] ?? 0) + by;
    }
  }

  /// Calls, once each, the watchers a write at [pointer] touches.
  void wrote(String pointer) {
    final at = _key(pointer);
    final called = <VoidCallback>{};
    void call(Set<VoidCallback>? set) {
      for (final onWrite in [...?set]) {
        if (called.add(onWrite)) onWrite();
      }
    }

    for (var up = at; ; up = up.substring(0, up.lastIndexOf('/'))) {
      call(_byPath[up]);
      if (up.isEmpty) break;
    }
    if ((_below[at] ?? 0) <= 0) return;
    for (final MapEntry(:key, :value) in _byPath.entries.toList()) {
      if (key.length > at.length &&
          key.codeUnitAt(at.length) == 0x2F &&
          key.startsWith(at)) {
        call(value);
      }
    }
  }
}
