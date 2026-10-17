import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_dom/jackdaw_dom.dart';
import 'package:jackdaw_web_bench/web_side.dart';
import 'package:web/web.dart' as web;

/// jackdaw_dom: the A2UI v1.0 messages go to a UiDomController as they
/// are, checked unless [trusted], and a UiDomView draws them.
final class JackdawDomSide implements WebSide {
  /// A side that checks what it applies, unless [trusted].
  new({this.trusted = false});

  /// Whether messages skip jackdaw's checks.
  final bool trusted;

  final UiDomController _ui = UiDomController(basicCatalog);
  UiDomView? _view;

  @override
  String get name => trusted ? 'jackdaw_dom_trusted' : 'jackdaw_dom';

  @override
  List<Object?> prepare(Map<String, Object?> message) => [message];

  @override
  List<Object?> mount(web.HTMLElement host, List<Object?> create) {
    _view = UiDomView(controller: _ui, surfaceId: 'bench', host: host);
    return create;
  }

  @override
  void apply(List<Object?> messages) =>
      _ui.applyAll(messages, trusted: trusted);

  @override
  void dispose() => _view?.dispose();
}
