import 'package:a2ui_core/a2ui_core.dart';
import 'package:jackdaw/jackdaw.dart';

/// The [UiAction] for an action an a2ui_core renderer reports, to send to
/// the agent with `uiActionMessage`.
UiAction uiActionFromA2ui(A2uiClientAction action) => UiAction(
  name: action.name,
  surfaceId: action.surfaceId,
  sourceComponentId: action.sourceComponentId,
  timestamp: action.timestamp,
  context: {...action.context},
);
