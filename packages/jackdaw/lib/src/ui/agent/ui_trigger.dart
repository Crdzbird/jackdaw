import 'package:jackdaw/src/ui/agent/ui_action.dart';
import 'package:jackdaw/src/ui/agent/ui_check_messages.dart';
import 'package:jackdaw/src/ui/eval/ui_evaluator.dart';
import 'package:jackdaw/src/ui/eval/ui_format_string.dart';
import 'package:jackdaw/src/ui/eval/ui_scope.dart';
import 'package:jackdaw/src/ui/surface/ui_component.dart';
import 'package:jackdaw/src/ui/surface/ui_surface.dart';

/// Runs the action of [component] on [surface] after a user gesture.
///
/// An event becomes the [UiAction] to send to the agent, with its context
/// resolved in [scope]; a function call runs on the renderer, so a link
/// can open, and gives `null`. Nothing happens, and `null` comes back,
/// while one of the component's checks fails.
UiAction? uiTrigger(
  UiSurface surface,
  UiComponent component,
  UiEvaluator evaluator, {
  UiScope? scope,
  DateTime? now,
}) {
  final active = (scope ?? UiScope(surface.data)).activated();
  if (uiCheckMessages(component, evaluator, active).isNotEmpty) return null;
  switch (component.props['action']) {
    case {
      'event': {'name': final String name} && final Map<String, Object?> event,
    }:
      final context = evaluator.evaluate(event['context'] ?? const {}, active);
      final message = event['userMessage'];
      return UiAction(
        name: name,
        surfaceId: surface.id,
        sourceComponentId: component.id,
        timestamp: now ?? DateTime.now(),
        context: context is Map<String, Object?> ? context : const {},
        userMessage: message == null
            ? null
            : uiText(evaluator.evaluate(message, active)),
        dataModel: surface.sendDataModel ? surface.data.root : null,
      );
    case {'functionCall': final Object call}:
      evaluator.evaluate(call, active);
  }
  return null;
}
