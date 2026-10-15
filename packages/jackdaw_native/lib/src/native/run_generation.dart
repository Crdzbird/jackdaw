import 'dart:async';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';
import 'package:jackdaw_native/src/native/check_status.dart';
import 'package:jackdaw_native/src/native/native_run.dart';
import 'package:jackdaw_native/src/native/session_events.dart';

/// Runs request [id] once [previous] completes, starting it natively with
/// [submit], which returns the native status, and delivering its events
/// through [events] to [controller]. Completes when the generation has
/// fully stopped natively.
Future<void> runGeneration(
  Future<void> previous,
  SessionEvents events,
  int id,
  int Function() submit,
  StreamController<ModelEvent> controller,
) async {
  await previous;
  if (!controller.hasListener) return;
  final finished = Completer<void>();
  events.finished[id] = finished;
  events.runs[id] = NativeRun(controller);
  final status = submit();
  if (status == jackdaw_status.JACKDAW_OK.value) {
    await finished.future;
    return;
  }
  events.finished.remove(id);
  events.runs.remove(id)?.fail(nativeError(status));
}
