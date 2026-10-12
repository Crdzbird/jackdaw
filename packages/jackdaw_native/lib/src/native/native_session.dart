import 'dart:async';
import 'dart:ffi';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';
import 'package:jackdaw_native/src/native/check_status.dart';
import 'package:jackdaw_native/src/native/create_session.dart';
import 'package:jackdaw_native/src/native/native_generate_options.dart';
import 'package:jackdaw_native/src/native/native_model.dart';
import 'package:jackdaw_native/src/native/native_run.dart';
import 'package:jackdaw_native/src/native/native_session_options.dart';
import 'package:jackdaw_native/src/native/native_stats.dart';
import 'package:jackdaw_native/src/native/session_events.dart';
import 'package:jackdaw_native/src/native/submit_generation.dart';

/// A native context with its own worker thread.
///
/// Generation runs on the worker; tokens reach Dart through a
/// `NativeCallable.listener`, so the calling isolate never blocks.
/// Cancelling a stream returned by [generate] stops native decoding.
final class NativeSession {
  /// Creates a session on [model].
  factory(
    NativeModel model, {
    NativeSessionOptions options = const NativeSessionOptions(),
  }) {
    final events = SessionEvents();
    final pointer = createSession(model, options, events.callable);
    return NativeSession._(pointer, events..session = pointer);
  }

  new _(this._pointer, this._events);

  final Pointer<jackdaw_session> _pointer;
  final SessionEvents _events;
  int _nextId = 1;
  Future<void> _queue = Future<void>.value();

  /// Streams the continuation of [prompt].
  ///
  /// Requests run one at a time in call order; a request waits until the
  /// previous one, including a cancelled one, has fully stopped.
  Stream<ModelEvent> generate(String prompt, NativeGenerateOptions options) {
    final id = _nextId++;
    late final StreamController<ModelEvent> controller;
    controller = StreamController<ModelEvent>(
      onListen: () => _queue = _run(_queue, id, prompt, options, controller),
      onCancel: () => _cancel(id),
    );
    return controller.stream;
  }

  /// Completes once every request started so far has stopped natively.
  Future<void> get idle => _queue;

  Future<void> _run(
    Future<void> previous,
    int id,
    String prompt,
    NativeGenerateOptions options,
    StreamController<ModelEvent> controller,
  ) async {
    await previous;
    if (!controller.hasListener) return;
    final finished = Completer<void>();
    _events.finished[id] = finished;
    _events.runs[id] = NativeRun(controller);
    final status = submitGeneration(_pointer, id, prompt, options);
    if (status == jackdaw_status.JACKDAW_OK.value) {
      await finished.future;
      return;
    }
    _events.finished.remove(id);
    _events.runs.remove(id)?.fail(nativeError(status));
  }

  void _cancel(int id) {
    if (_events.runs.remove(id) == null) return;
    jackdaw_session_cancel(_pointer, id);
  }

  /// Counts and timings of the last finished generation.
  NativeStats get stats => _events.stats;

  /// Stops any generation, joins the worker and frees the session.
  void dispose() {
    _events.runs.clear();
    for (final pending in _events.finished.values) {
      pending.complete();
    }
    _events.finished.clear();
    jackdaw_session_free(_pointer);
    _events.callable.close();
  }
}
