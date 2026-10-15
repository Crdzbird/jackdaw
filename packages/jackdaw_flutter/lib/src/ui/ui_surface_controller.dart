import 'package:flutter/foundation.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/ui/builders/basic_ui_builders.dart';
import 'package:jackdaw_flutter/src/ui/ui_widget_builder.dart';

/// The surfaces of a catalog for a Flutter app: what the agent shows, what
/// the user enters, and the actions that go back to the agent. Changes go
/// through here and notify listeners, so `UiSurfaceView`s redraw. Give the
/// agent [tool], or call [generate] for UI as a whole answer, and send
/// [onAction]'s actions to the agent with `uiActionMessage`.
final class UiSurfaceController extends ChangeNotifier {
  /// Creates a controller for [catalog]. [host] decides which links and
  /// images may load, [functions] implements the catalog's functions and
  /// [builders] draws its components.
  factory(
    UiCatalog catalog, {
    UiHost host,
    Map<String, UiFunctionBody>? functions,
    Map<String, UiWidgetBuilder> builders,
    void Function(UiAction action)? onAction,
  }) = UiSurfaceController._;

  new _(
    UiCatalog catalog, {
    UiHost host = const UiHost(),
    Map<String, UiFunctionBody>? functions,
    this.builders = basicUiBuilders,
    this.onAction,
  }) : surfaces = UiSurfaces(catalog),
       evaluator = UiEvaluator(catalog, functions: functions, host: host);

  /// The surfaces and their data.
  final UiSurfaces surfaces;

  /// Evaluates bindings, checks and function calls.
  final UiEvaluator evaluator;

  /// The builders of the components, by name; every view uses them.
  final Map<String, UiWidgetBuilder> builders;

  /// Receives what the user did on a surface.
  void Function(UiAction action)? onAction;

  /// A `render_ui` tool that shows screens in [format] here; see `uiTool`.
  Tool<List<Object?>> tool({
    String name = 'render_ui',
    UiFormat format = UiFormat.tree,
  }) => uiTool(
    surfaces,
    name: name,
    format: format,
    onShown: (_) => notifyListeners(),
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
  ).whenComplete(notifyListeners);

  /// Shows again the UI the [tool] showed in [history]; see `uiReplay`.
  void replay(List<Message> history, {String tool = 'render_ui'}) {
    uiReplay(surfaces, history, tool: tool);
    notifyListeners();
  }

  /// Applies A2UI messages from any agent and returns their problems.
  List<UiProblem> applyAll(List<Object?> messages) {
    final problems = surfaces.applyAll(messages);
    notifyListeners();
    return problems;
  }

  /// Writes [value] at [pointer] in the data of [surfaceId], as inputs do.
  void write(String surfaceId, String pointer, Object? value) {
    surfaces.surfaces[surfaceId]?.data.write(pointer, value);
    notifyListeners();
  }

  /// Runs the action of [component] on [surfaceId] in [scope], after a
  /// press, and passes an event to [onAction].
  void trigger(String surfaceId, UiComponent component, UiScope scope) {
    final surface = surfaces.surfaces[surfaceId];
    if (surface == null) return;
    final action = uiTrigger(surface, component, evaluator, scope: scope);
    if (action != null) onAction?.call(action);
    notifyListeners();
  }
}
