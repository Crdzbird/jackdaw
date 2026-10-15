import 'dart:async';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/controller/chat_state.dart';
import 'package:jackdaw_flutter/src/controller/chat_turns.dart';
import 'package:jackdaw_flutter/src/ui/ui_surface_controller.dart';
import 'package:jackdaw_flutter/src/ui/ui_surface_controller_agent.dart';

/// Drives one agent session for a chat UI: send, approve and stop. Its
/// listenables come from a [ChatState].
///
/// With [ui], the chat shows the surfaces the agent builds, rebuilt from
/// the history it starts with, and what the user does on them is sent to
/// the agent, after the running turn if there is one.
final class ChatController {
  /// Creates a controller for [sessionId] of [agent], which needs a store.
  factory({
    required Agent agent,
    required String sessionId,
    List<Message> history = const [],
    UiSurfaceController? ui,
  }) {
    if (agent.store == null) {
      throw ArgumentError.value(agent, 'agent', 'needs a session store');
    }
    final chat = ChatController._(agent, sessionId, ChatState(history), ui);
    ui?.onAction ??= chat._act;
    ui?.replay(history);
    chat._turns.onIdle = chat._next;
    return chat;
  }

  new _(this.agent, this.sessionId, this.state, this.ui)
    : _turns = ChatTurns(state);

  /// The agent that answers.
  final Agent agent;

  /// The session this chat continues.
  final String sessionId;

  /// Everything the UI shows.
  final ChatState state;

  /// The surfaces the agent builds, when the chat shows UI.
  final UiSurfaceController? ui;

  final ChatTurns _turns;
  final List<Message> _waiting = [];

  /// Sends [text] as the user and streams the answer. Throws [StateError]
  /// at once, changing nothing, while a turn is running.
  Future<void> send(String text) => sendMessage(Message.user(text));

  /// Sends [message] as the user, such as a `uiActionMessage`, and streams
  /// the answer. Throws [StateError] at once while a turn is running.
  Future<void> sendMessage(Message message) {
    _turns.requireIdle();
    state.messages.value = List.unmodifiable([
      ...state.messages.value,
      message,
    ]);
    return _turns.drive(agent.send(sessionId, message));
  }

  /// Answers the approval request for [callId] and continues the session.
  Future<void> decide(String callId, ApprovalDecision decision) {
    _turns.requireIdle();
    state.approvals.value = [
      for (final request in state.approvals.value)
        if (request.call.id != callId) request,
    ];
    return _turns.drive(agent.decide(sessionId, {callId: decision}));
  }

  /// Stops the running turn at once; the returned future completes when
  /// the model and tools have been cancelled.
  Future<void> stop() => _turns.stop();

  /// Stops any turn and releases every listenable.
  Future<void> dispose() async {
    _waiting.clear();
    await _turns.dispose();
    state.dispose();
  }

  void _act(UiAction action) {
    _waiting.add(uiActionMessage(action));
    if (!_turns.busy) _next();
  }

  void _next() {
    if (_waiting.isEmpty) return;
    unawaited(sendMessage(_waiting.removeAt(0)));
  }
}
