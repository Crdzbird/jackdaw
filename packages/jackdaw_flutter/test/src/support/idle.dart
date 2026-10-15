import 'dart:async';

import 'package:jackdaw_flutter/jackdaw_flutter.dart';

/// Completes when [chat] is idle, at once when it already is.
Future<void> idle(ChatController chat) {
  final done = Completer<void>();
  void check() {
    if (chat.status.value == ChatStatus.idle && !done.isCompleted) {
      chat.status.removeListener(check);
      done.complete();
    }
  }

  chat.status.addListener(check);
  check();
  return done.future;
}
