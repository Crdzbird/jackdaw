import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_web_bench/jaspr_host.dart';
import 'package:jackdaw_web_bench/web_side.dart';
import 'package:web/web.dart' as web;

/// genui_jaspr: the messages are lowered to A2UI v0.9 ahead of time and
/// parsed and handled by a2ui_core's MessageProcessor when applied; its
/// Surface draws them in the page's one Jaspr app.
final class GenuiJasprSide implements WebSide {
  final MessageProcessor<JasprComponent> _processor =
      MessageProcessor<JasprComponent>(catalogs: [BasicJasprCatalog()]);

  @override
  String get name => 'genui_jaspr';

  @override
  List<Object?> prepare(Map<String, Object?> message) =>
      uiLowerToV09([message], basicCatalog);

  @override
  List<Object?> mount(web.HTMLElement host, List<Object?> create) {
    apply(create.take(1).toList());
    JasprHost.show(_processor.groupModel.getSurface('bench'));
    return create.skip(1).toList();
  }

  @override
  void apply(List<Object?> messages) => _processor.processMessages([
    for (final message in messages)
      A2uiMessage.fromJson(message! as Map<String, Object?>),
  ]);

  @override
  void dispose() => JasprHost.show(null);
}
