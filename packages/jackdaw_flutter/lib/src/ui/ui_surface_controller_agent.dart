import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/ui/ui_surface_controller.dart';

/// The ways an agent shows UI on a [UiSurfaceController].
extension UiSurfaceControllerAgent on UiSurfaceController {
  /// A `render_ui` tool that shows screens in [format] here; see `uiTool`.
  Tool<List<Object?>> tool({
    String name = 'render_ui',
    UiFormat format = UiFormat.tree,
  }) => uiTool(
    surfaces,
    name: name,
    format: format,
    onShown: (_) => changes.components(),
  );

  /// Asks [model] for UI as its whole answer and shows it; see
  /// `generateUi`.
  Future<List<UiProblem>> generate(
    LanguageModel model,
    List<Message> messages, {
    int repairs = 1,
    UiFormat format = UiFormat.tree,
    void Function(Object? reply)? onReply,
  }) => generateUi(
    model,
    messages,
    surfaces,
    repairs: repairs,
    format: format,
    onReply: onReply,
  ).whenComplete(changes.components);

  /// Shows again the UI the [tool] showed in [history]; see `uiReplay`.
  void replay(List<Message> history, {String tool = 'render_ui'}) {
    uiReplay(surfaces, history, tool: tool);
    changes.components();
  }
}
