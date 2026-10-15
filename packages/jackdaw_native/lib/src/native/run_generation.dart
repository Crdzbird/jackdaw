import 'dart:async';
import 'dart:ffi';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';
import 'package:jackdaw_native/src/native/check_status.dart';
import 'package:jackdaw_native/src/native/native_generate_options.dart';
import 'package:jackdaw_native/src/native/native_run.dart';
import 'package:jackdaw_native/src/native/session_events.dart';
import 'package:jackdaw_native/src/native/submit_generation.dart';

/// Runs request [id] on [session] once [previous] completes, delivering
/// its events through [events] to [controller], and completes when the
/// generation has fully stopped natively.
Future<void> runGeneration(
  Future<void> previous,
  Pointer<jackdaw_session> session,
  SessionEvents events,
  int id,
  String prompt,
  NativeGenerateOptions options,
  StreamController<ModelEvent> controller,
) async {
  await previous;
  if (!controller.hasListener) return;
  final finished = Completer<void>();
  events.finished[id] = finished;
  events.runs[id] = NativeRun(controller);
  final status = submitGeneration(session, id, prompt, options);
  if (status == jackdaw_status.JACKDAW_OK.value) {
    await finished.future;
    return;
  }
  events.finished.remove(id);
  events.runs.remove(id)?.fail(nativeError(status));
}
