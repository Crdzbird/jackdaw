import 'package:jackdaw/src/ui/surface/ui_data_model.dart';
import 'package:jackdaw/src/ui/surface/ui_message_parts.dart';
import 'package:jackdaw/src/ui/surface/ui_surface.dart';

/// Copies of the surfaces [messages] name, or `null` for those that do
/// not exist yet, so [uiRestore] can put them back.
Map<String, UiSurface?> uiSnapshot(
  Map<String, UiSurface> surfaces,
  Iterable<Object?> messages,
) => {
  for (final message in messages)
    if (uiMessageParts(message) case (_, {'surfaceId': final String id}))
      id: switch (surfaces[id]) {
        final surface? => UiSurface(
          id,
          surface.catalog,
          sendDataModel: surface.sendDataModel,
          data: UiDataModel(surface.data.root),
        )..components.addAll(surface.components),
        null => null,
      },
};

/// Puts the surfaces [saved] by [uiSnapshot] back into [surfaces]; a
/// surface that still exists is restored in place, so holders of it see
/// the old state again.
void uiRestore(Map<String, UiSurface> surfaces, Map<String, UiSurface?> saved) {
  for (final MapEntry(key: id, value: copy) in saved.entries) {
    final live = surfaces[id];
    if (copy == null) surfaces.remove(id);
    if (copy != null && live == null) surfaces[id] = copy;
    if (copy != null && live != null) {
      live.components
        ..clear()
        ..addAll(copy.components);
      live.data.write('/', copy.data.root);
    }
  }
}
