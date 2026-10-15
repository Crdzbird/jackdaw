import 'package:flutter/foundation.dart';
import 'package:jackdaw/jackdaw.dart';

/// The surfaces of a catalog for a Flutter app: what the agent shows, what
/// the user enters, and the actions that go back to the agent.
///
/// Every change goes through this controller, which notifies listeners, so
/// `UiSurfaceView`s redraw. Give the agent [tool], or call [generate] for
/// UI as a whole answer, and handle [onAction] by sending the action to
/// the agent with `uiActionMessage`.
final class UiSurfaceController extends ChangeNotifier {
  /// Creates a controller for [catalog]. [host] decides which links and
  /// images may load, and [functions] implements the catalog's functions.
  factory(
    UiCatalog catalog, {
    UiHost host,
    Map<String, UiFunctionBody>? functions,
    void Function(UiAction action)? onAction,
  }) = UiSurfaceController._;

  new _(
    UiCatalog catalog, {
    UiHost host = const UiHost(),
    Map<String, UiFunctionBody>? functions,
    this.onAction,
  }) : surfaces = UiSurfaces(catalog),
       evaluator = UiEvaluator(catalog, functions: functions, host: host);

  /// The surfaces and their data.
  final UiSurfaces surfaces;

  /// Evaluates bindings, checks and function calls.
  final UiEvaluator evaluator;

  /// Receives what the user did on a surface.
  void Function(UiAction action)? onAction;

  /// A `render_ui` tool that shows its UI here.
  Tool<List<Object?>> tool({
    String name = 'render_ui',
    bool adoptOrphans = true,
  }) => uiTool(
    surfaces,
    name: name,
    adoptOrphans: adoptOrphans,
    onShown: (_) => notifyListeners(),
  );

  /// Asks [model] for UI as its whole answer and shows it; see
  /// `generateUi`.
  Future<List<UiProblem>> generate(
    LanguageModel model,
    List<Message> messages, {
    int repairs = 1,
  }) async {
    final problems = await generateUi(
      model,
      messages,
      surfaces,
      repairs: repairs,
    );
    notifyListeners();
    return problems;
  }

  /// Applies A2UI messages from any agent and returns their problems.
  List<UiProblem> applyAll(List<Object?> messages) {
    final problems = surfaces.applyAll(messages);
    notifyListeners();
    return problems;
  }

  /// Writes [value] at [pointer] in the data of [surfaceId], as an input
  /// does when the user changes it.
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
