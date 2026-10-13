/// Flutter widgets for jackdaw agents.
///
/// `ChatController` drives an agent session and `ChatView` shows it:
/// transcript, streamed answer, tool approvals and a composer. Streamed
/// text updates at most once per frame and rebuilds only the bubble that
/// shows it.
library;

export 'src/controller/chat_controller.dart';
export 'src/controller/chat_listenables.dart';
export 'src/controller/chat_state.dart';
export 'src/controller/chat_status.dart';
export 'src/controller/frame_text.dart';
export 'src/widgets/approval_card.dart';
export 'src/widgets/approval_list.dart';
export 'src/widgets/bubble_frame.dart';
export 'src/widgets/chat_bubble.dart';
export 'src/widgets/chat_composer.dart';
export 'src/widgets/chat_message_list.dart';
export 'src/widgets/chat_view.dart';
export 'src/widgets/paragraphs.dart';
export 'src/widgets/streaming_bubble.dart';
