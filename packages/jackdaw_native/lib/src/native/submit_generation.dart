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
  final text = prompt.toNativeUtf8(allocator: arena);
  return jackdaw_session_generate(
    session,
    id,
    text.cast(),
    text.length,
    _params(arena, options),
  );
});

/// Starts request [id] for the chat [messages] on [session], whose worker
/// renders them with the model's chat template, and returns the status.
int submitChat(
  Pointer<jackdaw_session> session,
  int id,
  List<(String, String)> messages,
  NativeGenerateOptions options,
) => using((arena) {
  final chat = arena<jackdaw_chat_message>(messages.length);
  for (final (i, (role, content)) in messages.indexed) {
    chat[i]
      ..role = role.toNativeUtf8(allocator: arena).cast()
      ..content = content.toNativeUtf8(allocator: arena).cast();
  }
  return jackdaw_session_generate_chat(
    session,
    id,
    chat,
    messages.length,
    _params(arena, options),
  );
});

Pointer<jackdaw_generate_params> _params(
  Arena arena,
  NativeGenerateOptions options,
) {
  final params = arena<jackdaw_generate_params>();
  params.ref
    ..temperature = options.temperature
    ..top_k = options.topK
    ..top_p = options.topP
    ..seed = options.seed
    ..max_tokens = options.maxTokens
    ..grammar =
        options.grammar?.toNativeUtf8(allocator: arena).cast() ?? nullptr;
  return params;
}
