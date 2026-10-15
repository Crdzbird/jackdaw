/// Flutter widgets for jackdaw agents.
///
/// `ChatController` drives an agent session and `ChatView` shows it:
/// transcript, streamed answer, tool approvals and a composer. Streamed
/// text updates at most once per frame and rebuilds only the bubble that
/// shows it. `UiSurfaceController` and `UiSurfaceView` draw the A2UI
/// surfaces an agent builds.
library;

export 'src/controller/chat_controller.dart';
export 'src/controller/chat_listenables.dart';
export 'src/controller/chat_state.dart';
export 'src/controller/chat_status.dart';
export 'src/controller/frame_text.dart';
export 'src/ui/builders/basic_ui_builders.dart';
export 'src/ui/builders/ui_text_field.dart';
export 'src/ui/ui_node.dart';
export 'src/ui/ui_node_values.dart';
export 'src/ui/ui_surface_controller.dart';
export 'src/ui/ui_surface_view.dart';
export 'src/ui/ui_widget_builder.dart';
export 'src/widgets/approval_card.dart';
export 'src/widgets/approval_list.dart';
export 'src/widgets/bubble_frame.dart';
export 'src/widgets/chat_bubble.dart';
export 'src/widgets/chat_composer.dart';
export 'src/widgets/chat_message_list.dart';
export 'src/widgets/chat_view.dart';
export 'src/widgets/paragraphs.dart';
export 'src/widgets/streaming_bubble.dart';
