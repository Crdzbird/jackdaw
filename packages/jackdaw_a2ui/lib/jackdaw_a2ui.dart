/// A2UI renderers for jackdaw agents.
///
/// `A2uiCoreTarget` sends the UI a jackdaw agent builds to an a2ui_core
/// `MessageProcessor`, so a renderer built on a2ui_core draws it, and
/// `uiActionFromA2ui` turns what the user does there back into a message
/// for the agent. For genui and other libraries, see `UiTarget` in
/// jackdaw.
library;

export 'src/a2ui_core_target.dart';
export 'src/ui_action_from_a2ui.dart';
