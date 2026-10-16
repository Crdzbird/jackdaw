import 'package:flutter/foundation.dart';
import 'package:jackdaw/jackdaw.dart';

/// What changed on the surfaces of a controller. Listeners hear when
/// components change; write listeners hear each data write with its
/// pointer; and watchers hear only writes that touch the paths they
/// watch, so a view redraws only the components bound near a write.
final class UiChanges extends ChangeNotifier {
  final List<void Function(String surfaceId, String pointer)> _writes = [];
  final Map<String, UiWatchers> _watchers = {};

  /// Calls [listener] after each data write.
  void addWriteListener(
    void Function(String surfaceId, String pointer) listener,
  ) => _writes.add(listener);

  /// Stops calling [listener].
  void removeWriteListener(
    void Function(String surfaceId, String pointer) listener,
  ) => _writes.remove(listener);

  /// Calls [onWrite] after each write to [surfaceId] that touches one of
  /// [paths]: the path itself, a value inside it or one holding it.
  void watch(String surfaceId, Set<String> paths, VoidCallback onWrite) =>
      (_watchers[surfaceId] ??= UiWatchers()).add(paths, onWrite);

  /// Stops [onWrite] from watching [paths] of [surfaceId].
  void unwatch(String surfaceId, Set<String> paths, VoidCallback onWrite) {
    final watchers = _watchers[surfaceId];
    if (watchers == null || !watchers.remove(paths, onWrite)) return;
    _watchers.remove(surfaceId);
  }

  /// Tells listeners that components changed.
  void components() => notifyListeners();

  /// Tells write listeners, and the watchers it touches, that [pointer]
  /// of [surfaceId] changed. A listener added or removed meanwhile may be
  /// skipped or called.
  void wrote(String surfaceId, String pointer) {
    for (var i = 0; i < _writes.length; i++) {
      _writes[i](surfaceId, pointer);
    }
    _watchers[surfaceId]?.wrote(pointer);
  }

  /// Announces what [messages] changed: data writes by pointer, and
  /// any other message as a change of components.
  void announce(Iterable<Object?> messages) {
    var components = false;
    for (final message in messages) {
      switch (uiMessageParts(message)) {
        case ('updateDataModel', {'surfaceId': final String id} && final body):
          wrote(id, body['path'] as String? ?? '/');
        case _:
          components = true;
      }
    }
    if (components) notifyListeners();
  }
}
