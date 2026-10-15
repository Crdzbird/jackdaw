import 'dart:async';
import 'dart:ffi';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';
import 'package:jackdaw_native/src/native/create_session.dart';
import 'package:jackdaw_native/src/native/native_generate_options.dart';
import 'package:jackdaw_native/src/native/native_model.dart';
import 'package:jackdaw_native/src/native/native_session_options.dart';
import 'package:jackdaw_native/src/native/native_stats.dart';
import 'package:jackdaw_native/src/native/run_generation.dart';
import 'package:jackdaw_native/src/native/session_events.dart';
import 'package:jackdaw_native/src/native/session_state.dart';

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
      onListen: () => _queue = runGeneration(
        _queue,
        _pointer,
        _events,
        id,
        prompt,
        options,
        controller,
      ),
      onCancel: () => _cancel(id),
    );
    return controller.stream;
  }

  /// Completes once every request started so far has stopped natively.
  Future<void> get idle => _queue;

  /// Writes the tokens processed so far, and their cache, to [path] once
  /// the requests already started have stopped; see [load].
  Future<void> save(String path) =>
      _after(() => saveSessionState(_pointer.address, path));

  /// Replaces the cache with the state [save] wrote to [path] and returns
  /// the number of tokens restored, or 0 when the file does not fit.
  Future<int> load(String path) =>
      _after(() => loadSessionState(_pointer.address, path));

  Future<T> _after<T>(Future<T> Function() transfer) {
    final result = _queue.then((_) => transfer());
    _queue = result.then((_) {}, onError: (Object _) {});
    return result;
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
