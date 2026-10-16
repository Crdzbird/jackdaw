import 'package:jackdaw/jackdaw.dart';

/// The surfaces of a catalog for a web page. Messages and inputs go
/// through here: a data write reaches only the watchers of the paths it
/// touches, and any other change reaches the listeners of its surface.
final class UiDomController {
  /// Creates a controller for [catalog]; [host] decides which links and
  /// images may load and [functions] implements the catalog's functions.
  factory(
    UiCatalog catalog, {
    UiHost host,
    Map<String, UiFunctionBody>? functions,
    void Function(UiAction action)? onAction,
  }) = UiDomController._;

  new _(
    UiCatalog catalog, {
    UiHost host = const UiHost(),
    Map<String, UiFunctionBody>? functions,
    this.onAction,
  }) : surfaces = UiSurfaces(catalog),
       evaluator = UiEvaluator(catalog, functions: functions, host: host);

  /// The surfaces and their data.
  final UiSurfaces surfaces;

  /// Evaluates bindings, checks and function calls.
  final UiEvaluator evaluator;

  /// Receives what the user did on a surface.
  void Function(UiAction action)? onAction;

  final Map<String, UiWatchers> _watchers = {};
  final Map<String, List<void Function()>> _listeners = {};

  /// Applies A2UI messages from any agent and returns their problems.
  List<UiProblem> applyAll(List<Object?> messages) {
    final problems = surfaces.applyAll(messages);
    final changed = <String>{};
    for (final message in messages) {
      if (uiMessageParts(message) case (
        final kind,
        {'surfaceId': final String id} && final body,
      )) {
        if (kind == 'updateDataModel') {
          _watchers[id]?.wrote(body['path'] as String? ?? '/');
          continue;
        }
        changed.add(id);
      }
    }
    changed.forEach(_changed);
    return problems;
  }

  /// Writes [value] at [pointer] in the data of [surfaceId], as inputs do.
  void write(String surfaceId, String pointer, Object? value) {
    final surface = surfaces.surfaces[surfaceId];
    if (surface == null) return;
    surface.data.write(pointer, value);
    _watchers[surfaceId]?.wrote(pointer);
  }

  /// Runs the action of [component] on [surfaceId] in [scope], after a
  /// press, and passes an event to [onAction].
  void trigger(String surfaceId, UiComponent component, UiScope scope) {
    final surface = surfaces.surfaces[surfaceId];
    if (surface == null) return;
    final action = uiTrigger(surface, component, evaluator, scope: scope);
    if (action != null) onAction?.call(action);
    _changed(surfaceId);
  }

  /// Calls [onWrite] after each write to [surfaceId] that touches one of
  /// [paths], and returns what stops it.
  void Function() watch(
    String surfaceId,
    Set<String> paths,
    void Function() onWrite,
  ) {
    final watchers = (_watchers[surfaceId] ??= UiWatchers())
      ..add(paths, onWrite);
    return () {
      if (watchers.remove(paths, onWrite)) _watchers.remove(surfaceId);
    };
  }

  /// Calls [onChange] when anything but data changes on [surfaceId], and
  /// returns what stops it.
  void Function() listen(String surfaceId, void Function() onChange) {
    final listeners = (_listeners[surfaceId] ??= [])..add(onChange);
    return () => listeners.remove(onChange);
  }

  void _changed(String surfaceId) {
    for (final listener in [...?_listeners[surfaceId]]) {
      listener();
    }
  }
}
