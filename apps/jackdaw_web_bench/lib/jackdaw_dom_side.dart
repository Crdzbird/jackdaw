import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_dom/jackdaw_dom.dart';
import 'package:jackdaw_web_bench/web_side.dart';
import 'package:web/web.dart' as web;

/// jackdaw_dom: the A2UI v1.0 messages go to a UiDomController as they
/// are, and a UiDomView draws them.
final class JackdawDomSide implements WebSide {
  final UiDomController _ui = UiDomController(basicCatalog);
  UiDomView? _view;

  @override
  String get name => 'jackdaw_dom';

  @override
  List<Object?> prepare(Map<String, Object?> message) => [message];

  @override
  List<Object?> mount(web.HTMLElement host, List<Object?> create) {
    _view = UiDomView(controller: _ui, surfaceId: 'bench', host: host);
    return create;
  }

  @override
  void apply(List<Object?> messages) => _ui.applyAll(messages);

  @override
  void dispose() => _view?.dispose();
}
