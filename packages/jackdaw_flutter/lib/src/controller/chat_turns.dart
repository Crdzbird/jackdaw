import 'dart:async';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/controller/chat_state.dart';
import 'package:jackdaw_flutter/src/controller/chat_status.dart';

/// Runs one agent turn at a time into a [ChatState].
final class ChatTurns {
  /// Creates a runner that applies events to [state].
  factory(ChatState state) = ChatTurns._;

  new _(this.state);

  /// The state events go into.
  final ChatState state;

  StreamSubscription<AgentEvent>? _run;
  Completer<void>? _turn;

  /// Whether a turn is running.
  bool get busy => _run != null;

  /// Called after each turn ends, for work that waited for it.
  void Function()? onIdle;

  /// Throws [StateError] while a turn is running.
  void requireIdle() {
    if (busy) throw StateError('a turn is already running');
  }

  /// Runs the turn [events] and completes when it ends.
  Future<void> drive(Stream<AgentEvent> events) async {
    state.begin();
    final turn = _turn = Completer<void>();
    _run = events.listen(
      state.apply,
      onError: (Object failure) {
        state.error = failure;
        end(ChatStatus.failed);
      },
      onDone: end,
    );
    await turn.future;
  }

  /// Ends the running turn, switching to [next] when it is given.
  void end([ChatStatus? next]) {
    final turn = _turn;
    if (turn == null) return;
    _turn = null;
    _run = null;
    state.end(next);
    turn.complete();
    onIdle?.call();
  }

  /// Ends the running turn and cancels its events.
  Future<void> stop() async {
    final run = _run;
    end(ChatStatus.idle);
    await run?.cancel();
  }

  /// Cancels any turn without changing the state.
  Future<void> dispose() async {
    await _run?.cancel();
    _turn?.complete();
  }
}
