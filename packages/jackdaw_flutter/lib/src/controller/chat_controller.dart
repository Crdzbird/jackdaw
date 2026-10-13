import 'dart:async';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/controller/chat_state.dart';
import 'package:jackdaw_flutter/src/controller/chat_status.dart';

/// Drives one agent session for a chat UI: send, approve and stop. Its
/// listenables come from a [ChatState].
final class ChatController {
  /// Creates a controller for [sessionId] of [agent], which needs a store.
  factory({
    required Agent agent,
    required String sessionId,
    List<Message> history = const [],
  }) {
    if (agent.store == null) {
      throw ArgumentError.value(agent, 'agent', 'needs a session store');
    }
    return ChatController._(agent, sessionId, ChatState(history));
  }

  new _(this.agent, this.sessionId, this.state);

  /// The agent that answers.
  final Agent agent;

  /// The session this chat continues.
  final String sessionId;

  /// Everything the UI shows.
  final ChatState state;

  StreamSubscription<AgentEvent>? _run;
  Completer<void>? _turn;

  /// Sends [text] as the user and streams the answer. Throws [StateError]
  /// at once, changing nothing, while a turn is running.
  Future<void> send(String text) {
    _idle();
    final message = Message.user(text);
    state.messages.value = List.unmodifiable([
      ...state.messages.value,
      message,
    ]);
    return _drive(agent.send(sessionId, message));
  }

  /// Answers the approval request for [callId] and continues the session.
  Future<void> decide(String callId, ApprovalDecision decision) {
    _idle();
    state.approvals.value = [
      for (final request in state.approvals.value)
        if (request.call.id != callId) request,
    ];
    return _drive(agent.decide(sessionId, {callId: decision}));
  }

  /// Stops the running turn at once; the returned future completes when
  /// the model and tools have been cancelled.
  Future<void> stop() async {
    final run = _run;
    _end(ChatStatus.idle);
    await run?.cancel();
  }

  /// Stops any turn and releases every listenable.
  Future<void> dispose() async {
    await _run?.cancel();
    _turn?.complete();
    state.dispose();
  }

  void _idle() {
    if (_run != null) throw StateError('a turn is already running');
  }

  Future<void> _drive(Stream<AgentEvent> events) async {
    state.begin();
    final turn = _turn = Completer<void>();
    _run = events.listen(
      state.apply,
      onError: (Object failure) {
        state.error = failure;
        _end(ChatStatus.failed);
      },
      onDone: () => _end(state.status.value),
    );
    await turn.future;
  }

  void _end(ChatStatus next) {
    _run = null;
    state.end(next);
    _turn?.complete();
    _turn = null;
  }
}
