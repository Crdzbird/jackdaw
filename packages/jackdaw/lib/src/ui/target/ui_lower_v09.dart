import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/surface/ui_message_parts.dart';
import 'package:jackdaw/src/ui/target/ui_lower_parts.dart';

const String _basicV10 =
    'https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json';
const String _basicV09 =
    'https://a2ui.org/specification/v0_9/catalogs/basic/catalog.json';

/// The A2UI v1.0 [messages] written for A2UI v0.9, as genui 0.10 reads
/// them.
///
/// A `createSurface` with components or data becomes a `createSurface`
/// that names its catalog, an `updateComponents` and an `updateDataModel`.
/// `@path` and `@call` lose their prefix, calls state what they return,
/// checks get a message, a `null` value deletes by leaving the value out,
/// and props new in v1.0 are dropped.
List<Map<String, Object?>> uiLowerToV09(
  List<Map<String, Object?>> messages,
  UiCatalog catalog,
) => [for (final message in messages) ..._lower(message, catalog)];

List<Map<String, Object?>> _lower(Map<String, Object?> message, UiCatalog c) {
  Map<String, Object?> envelope(String kind, Map<String, Object?> body) => {
    'version': 'v0.9',
    kind: body,
  };
  final (kind, body) =
      uiMessageParts(message) ?? ('', const <String, Object?>{});
  final id = body['surfaceId'];
  final components = [
    if (body['components'] case final List<Object?> list)
      for (final component in list.whereType<Map<String, Object?>>())
        uiLowerComponentV09(component, c),
  ];
  return switch (kind) {
    'createSurface' => [
      envelope(kind, {
        'surfaceId': id,
        'catalogId': switch (body['catalogId'] ?? c.id) {
          _basicV10 => _basicV09,
          final other => other,
        },
        if (body['sendDataModel'] case final bool send) 'sendDataModel': send,
      }),
      if (components.isNotEmpty)
        envelope('updateComponents', {
          'surfaceId': id,
          'components': components,
        }),
      if (body['dataModel'] case final Object data)
        envelope('updateDataModel', {
          'surfaceId': id,
          'path': '/',
          'value': data,
        }),
    ],
    'updateComponents' => [
      envelope(kind, {'surfaceId': id, 'components': components}),
    ],
    'updateDataModel' => [
      envelope(kind, {
        'surfaceId': id,
        'path': ?body['path'],
        'value': ?body['value'],
      }),
    ],
    '' => const [],
    _ => [envelope(kind, body)],
  };
}
