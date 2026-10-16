import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_dom/jackdaw_dom.dart';
import 'package:web/web.dart' as web;

/// Draws a greeting with a field that writes the name it greets.
void main() {
  web.document.head!.append(web.HTMLStyleElement()..textContent = uiDomStyles);
  final ui = UiDomController(basicCatalog)
    ..applyAll([
      {
        'version': 'v1.0',
        'createSurface': {
          'surfaceId': 'main',
          'components': [
            {
              'id': 'root',
              'component': 'Column',
              'children': ['hello', 'name'],
            },
            {
              'id': 'hello',
              'component': 'Text',
              'text': {'@path': '/name'},
            },
            {
              'id': 'name',
              'component': 'TextField',
              'label': 'Name',
              'value': {'@path': '/name'},
            },
          ],
          'dataModel': {'name': 'world'},
        },
      },
    ]);
  UiDomView(controller: ui, surfaceId: 'main', host: web.document.body!);
}
