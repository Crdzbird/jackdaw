import 'package:flutter/foundation.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/controller/chat_controller.dart';
import 'package:jackdaw_flutter/src/controller/chat_status.dart';

/// The parts of a [ChatController] that widgets listen to.
extension ChatListenables on ChatController {
  /// The transcript, including tool messages.
  ValueListenable<List<Message>> get messages => state.messages;

  /// Text of the answer being generated, empty between turns.
  ValueListenable<String> get streaming => state.streaming;

  /// What the chat is doing.
  ValueListenable<ChatStatus> get status => state.status;

  /// Tool calls waiting for the user's decision.
  ValueListenable<List<AgentApprovalRequested>> get approvals =>
      state.approvals;
}
