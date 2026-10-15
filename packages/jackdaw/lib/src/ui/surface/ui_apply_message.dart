import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/surface/ui_component_list.dart';
import 'package:jackdaw/src/ui/surface/ui_data_model.dart';
import 'package:jackdaw/src/ui/surface/ui_message_parts.dart';
import 'package:jackdaw/src/ui/surface/ui_problem.dart';
import 'package:jackdaw/src/ui/surface/ui_problem_code.dart';
import 'package:jackdaw/src/ui/surface/ui_surface.dart';

/// Applies the validated A2UI message [message] to [surfaces], creating
/// new surfaces with [catalog], and returns what kept it from applying.
List<UiProblem> uiApplyMessage(
  Map<String, UiSurface> surfaces,
  UiCatalog catalog,
  Object? message,
) {
  final (kind, body) = uiMessageParts(message)!;
  final id = body['surfaceId']! as String;
  final surface = surfaces[id];
  if ((kind == 'createSurface') == (surface != null)) {
    final problem = surface == null ? 'There is no' : 'There is already a';
    return [
      UiProblem(
        UiProblemCode.validationFailed,
        '$problem surface $id.',
        surfaceId: id,
        path: '/$kind/surfaceId',
      ),
    ];
  }
  final list = body['components'] as List<Object?>? ?? const [];
  final at = '/$kind/components';
  return switch (kind) {
    'createSurface' => uiAddComponents(
      _create(surfaces, catalog, id, body),
      list,
      at,
    ),
    'updateComponents' => uiAddComponents(surface!, list, at),
    'updateDataModel' => _write(surface!, body),
    _ => _delete(surfaces, id),
  };
}

UiSurface _create(
  Map<String, UiSurface> surfaces,
  UiCatalog catalog,
  String id,
  Map<String, Object?> body,
) => surfaces[id] = UiSurface(
  id,
  catalog,
  sendDataModel: body['sendDataModel'] == true,
  data: UiDataModel(body['dataModel']),
);

List<UiProblem> _write(UiSurface surface, Map<String, Object?> body) {
  surface.data.write(body['path'] as String? ?? '/', body['value']);
  return const [];
}

List<UiProblem> _delete(Map<String, UiSurface> surfaces, String id) {
  surfaces.remove(id);
  return const [];
}
