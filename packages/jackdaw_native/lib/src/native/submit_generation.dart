import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';
import 'package:jackdaw_native/src/native/native_generate_options.dart';

/// Starts request [id] for [prompt] on [session] and returns the status.
///
/// The native core copies the prompt and grammar, so the buffers are freed
/// as soon as this returns.
int submitGeneration(
  Pointer<jackdaw_session> session,
  int id,
  String prompt,
  NativeGenerateOptions options,
) => using((arena) {
  final params = arena<jackdaw_generate_params>();
  params.ref
    ..temperature = options.temperature
    ..top_k = options.topK
    ..top_p = options.topP
    ..seed = options.seed
    ..max_tokens = options.maxTokens
    ..grammar =
        options.grammar?.toNativeUtf8(allocator: arena).cast() ?? nullptr;
  final text = prompt.toNativeUtf8(allocator: arena);
  return jackdaw_session_generate(
    session,
    id,
    text.cast(),
    text.length,
    params,
  );
});
