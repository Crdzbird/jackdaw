import 'package:flutter/widgets.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/controller/chat_status.dart';
import 'package:jackdaw_flutter/src/controller/frame_text.dart';

/// The listenable state of a chat, updated from agent events.
///
/// Each piece is its own listenable, so a widget rebuilds only for what it
/// shows: streamed text changes at most once per frame and touches only the
/// bubble that shows it, never the message list.
final class ChatState {
  /// Creates state starting from [history].
  factory(List<Message> history) = ChatState._;

  new _(List<Message> history)
    : messages = ValueNotifier(List.unmodifiable(history));

  /// The transcript, including tool messages.
  final ValueNotifier<List<Message>> messages;

  /// Text of the answer being generated, empty between turns.
  final FrameText streaming = FrameText();

  /// What the chat is doing.
  final ValueNotifier<ChatStatus> status = ValueNotifier(ChatStatus.idle);

  /// Tool calls waiting for the user's decision.
  final ValueNotifier<List<AgentApprovalRequested>> approvals = ValueNotifier(
    const [],
  );

  /// The error of the last failed turn.
  Object? error;

  final Map<int, GlobalKey> _layouts = {};
  List<Message>? _transcript;
  ChatStatus _settled = ChatStatus.idle;

  /// Key for the text of the message at [index] of the transcript, shared
  /// by the streaming bubble that will become that message, so its layout
  /// carries over.
  GlobalKey layoutKey(int index) => _layouts.putIfAbsent(index, GlobalKey.new);

  /// Marks the start of a turn.
  void begin() {
    error = null;
    _transcript = null;
    _settled = ChatStatus.idle;
    streaming.clear();
    status.value = ChatStatus.responding;
  }

  /// Applies one agent [event].
  void apply(AgentEvent event) => switch (event) {
    AgentTextDelta(:final text) => streaming.append(text),
    AgentApprovalRequested() => approvals.value = [...approvals.value, event],
    AgentFinished(:final messages, :final reason) => _finish(messages, reason),
    _ => null,
  };

  /// Marks the end of a turn: shows the final transcript, if the agent
  /// sent one, and switches to [next], or to what the agent's last event
  /// asked for when [next] is null. Both change in the same frame.
  void end([ChatStatus? next]) {
    if (_transcript case final transcript?) messages.value = transcript;
    _transcript = null;
    streaming.clear();
    status.value = next ?? _settled;
  }

  /// Releases every listenable.
  void dispose() {
    for (final notifier in [messages, streaming, status, approvals]) {
      notifier.dispose();
    }
  }

  void _finish(List<Message> transcript, AgentStopReason reason) {
    _transcript = List.unmodifiable(transcript);
    _settled = reason == AgentStopReason.awaitingApproval
        ? ChatStatus.awaitingApproval
        : ChatStatus.idle;
  }
}
