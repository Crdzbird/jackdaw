import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_dom/jackdaw_dom.dart';
import 'package:jackdaw_web_bench/bench_screen.dart';
import 'package:web/web.dart' as web;

/// The smallest page that draws the bench screen with jackdaw_dom, to
/// measure what the library adds to a page's script.
void main() {
  web.document.head!.append(web.HTMLStyleElement()..textContent = uiDomStyles);
  final ui = UiDomController(basicCatalog)..applyAll([uiFrameSurface(40)]);
  UiDomView(controller: ui, surfaceId: 'bench', host: web.document.body!);
}
