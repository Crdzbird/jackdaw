import 'package:flutter/foundation.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/ui/builders/basic_ui_builders.dart';
import 'package:jackdaw_flutter/src/ui/ui_changes.dart';
import 'package:jackdaw_flutter/src/ui/ui_widget_builder.dart';

/// The surfaces of a catalog for a Flutter app: what the agent shows, what
/// the user enters, and the actions that go back to the agent. Changes go
/// through here and notify listeners; [changes] tells views which part
/// changed. Give the agent `tool`, or call `generate` for UI as a whole
/// answer, and send [onAction]'s actions to the agent with
/// `uiActionMessage`.
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
       evaluator = UiEvaluator(catalog, functions: functions, host: host) {
    changes
      ..addListener(notifyListeners)
      ..addWriteListener((_, _) => notifyListeners());
  }

  /// The surfaces and their data.
  final UiSurfaces surfaces;

  /// Evaluates bindings, checks and function calls.
  final UiEvaluator evaluator;

  /// The builders of the components, by name; every view uses them.
  final Map<String, UiWidgetBuilder> builders;

  /// What changed: components, or data at a pointer.
  final UiChanges changes = UiChanges();

  /// Receives what the user did on a surface.
  void Function(UiAction action)? onAction;

  /// Applies A2UI messages from any agent and returns their problems; see
  /// [UiSurfaces.applyAll] for [trusted], which skips the checks.
  List<UiProblem> applyAll(List<Object?> messages, {bool trusted = false}) {
    final problems = surfaces.applyAll(messages, trusted: trusted);
    changes.announce(messages);
    return problems;
  }

  /// Writes [value] at [pointer] in the data of [surfaceId], as inputs do.
  void write(String surfaceId, String pointer, Object? value) {
    final surface = surfaces.surfaces[surfaceId];
    if (surface == null) return;
    surface.data.write(pointer, value);
    changes.wrote(surfaceId, pointer);
  }

  /// Runs the action of [component] on [surfaceId] in [scope], after a
  /// press, and passes an event to [onAction].
  void trigger(String surfaceId, UiComponent component, UiScope scope) {
    final surface = surfaces.surfaces[surfaceId];
    if (surface == null) return;
    final action = uiTrigger(surface, component, evaluator, scope: scope);
    if (action != null) onAction?.call(action);
    changes.components();
  }

  @override
  void dispose() {
    changes.dispose();
    super.dispose();
  }
}
