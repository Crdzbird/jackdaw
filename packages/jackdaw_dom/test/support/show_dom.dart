import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_dom/jackdaw_dom.dart';
import 'package:web/web.dart' as web;

/// A surface `s` of [components] with [data], drawn into a fresh element
/// of the page.
({UiDomController controller, UiDomView view, web.HTMLDivElement host}) showDom(
  List<Map<String, Object?>> components, {
  Map<String, Object?> data = const {},
  void Function(UiAction action)? onAction,
}) {
  final controller = UiDomController(basicCatalog, onAction: onAction)
    ..applyAll([
      {
        'version': 'v1.0',
        'createSurface': {
          'surfaceId': 's',
          'components': components,
          'dataModel': data,
        },
      },
    ]);
  final host = web.HTMLDivElement();
  web.document.body!.append(host);
  final view = UiDomView(controller: controller, surfaceId: 's', host: host);
  return (controller: controller, view: view, host: host);
}

/// A component [id] of [type] with the props [p].
Map<String, Object?> c(
  String id,
  String type, [
  Map<String, Object?> p = const {},
]) => {'id': id, 'component': type, ...p};

/// The A2UI message that writes [value] at [path] of surface `s`.
Map<String, Object?> write(String path, Object? value) => {
  'version': 'v1.0',
  'updateDataModel': {'surfaceId': 's', 'path': path, 'value': value},
};
