import 'package:flutter/widgets.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_bench/src/app/demo_catalog.dart';
import 'package:jackdaw_bench/src/app/studio_renderer.dart';
import 'package:jackdaw_bench/src/app/ui_studio_screen.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

/// Screens drawn by jackdaw_flutter, with the demo catalog: the A2UI v1.0
/// basic catalog plus the Panel component.
final class JackdawRenderer implements StudioRenderer {
  /// Creates the renderer; [onAction] describes each action the user
  /// takes on the screen.
  factory(void Function(String action) onAction) = JackdawRenderer._;

  new _(void Function(String action) onAction)
    : _ui = UiSurfaceController(
        demoCatalog,
        host: UiHost(allowUrl: (url) => url.scheme == 'https'),
        builders: demoUiBuilders,
        onAction: (action) => onAction('${action.name}: ${action.context}'),
      );

  final UiSurfaceController _ui;

  @override
  Future<List<UiProblem>> generate(
    LanguageModel model,
    List<Message> messages,
    void Function(Object? reply) onReply,
  ) => _ui.generate(model, messages, onReply: onReply);

  @override
  Widget view() => UiStudioScreen(ui: _ui);

  @override
  void dispose() => _ui.dispose();
}
