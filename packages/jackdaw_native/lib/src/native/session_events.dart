import 'dart:async';
import 'dart:ffi';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';
import 'package:jackdaw_native/src/native/native_exception.dart';
import 'package:jackdaw_native/src/native/native_run.dart';
import 'package:jackdaw_native/src/native/native_stats.dart';
import 'package:jackdaw_native/src/native/session_reads.dart';

/// Receives native events and routes them to the matching [NativeRun].
final class SessionEvents {
  /// Creates the listener; close [callable] after the session is freed.
  factory() = SessionEvents._;

  new _();

  /// Callback handed to the native session; runs on this isolate.
  late final NativeCallable<Void Function(Int64, Int32, Int32)> callable =
      NativeCallable.listener(_onEvent);

  /// Completes when the native side stops each request, by request id.
  final Map<int, Completer<void>> finished = {};

  /// Active runs by request id.
  final Map<int, NativeRun> runs = {};

  /// The session whose events arrive here.
  late Pointer<jackdaw_session> session;

  /// Statistics of the last finished generation.
  NativeStats get stats => readStats(session);

  void _onEvent(int id, int kind, int value) {
    final run = runs[id];
    if (kind == jackdaw_event_kind.JACKDAW_EVENT_PIECE.value) {
      final bytes = readPiece(session, value);
      run?.addBytes(bytes);
      return;
    }
    finished.remove(id)?.complete();
    runs.remove(id);
    if (run == null) return;
    if (kind == jackdaw_event_kind.JACKDAW_EVENT_DONE.value) {
      final now = stats;
      final usage = Usage(
        inputTokens: now.promptTokens,
        outputTokens: now.generatedTokens,
      );
      return run.finish(_reasons[value] ?? FinishReason.other, usage);
    }
    run.fail(NativeException(value, readSessionError(session)));
  }

  static final Map<int, FinishReason> _reasons = {
    jackdaw_finish_reason.JACKDAW_FINISH_STOP.value: FinishReason.stop,
    jackdaw_finish_reason.JACKDAW_FINISH_LENGTH.value: FinishReason.length,
  };
}
