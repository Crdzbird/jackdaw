import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';
import 'package:jackdaw_native/src/native/check_status.dart';
import 'package:jackdaw_native/src/native/native_model.dart';
import 'package:jackdaw_native/src/native/native_session_options.dart';

/// Creates a native session on [model] that reports to [callable].
Pointer<jackdaw_session> createSession(
  NativeModel model,
  NativeSessionOptions options,
  NativeCallable<Void Function(Int64, Int32, Int32)> callable,
) => using((arena) {
  final params = arena<jackdaw_session_params>();
  params.ref
    ..context_tokens = options.contextTokens
    ..threads = options.threads
    ..batch_tokens = options.batchTokens;
  final out = arena<Pointer<jackdaw_session>>();
  final callback = callable.nativeFunction;
  checkStatus(jackdaw_session_create(model.pointer, params, callback, out));
  return out.value;
});
