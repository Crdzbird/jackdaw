import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';
import 'package:jackdaw_native/src/native/native_stats.dart';

/// Copies the piece in [slot] out of [session] and frees the slot.
///
/// Returns no bytes when the slot was already released, which happens for
/// pieces of a request that was cancelled.
List<int> readPiece(Pointer<jackdaw_session> session, int slot) =>
    using((arena) {
      final length = arena<Int32>();
      jackdaw_session_read(session, slot, nullptr, 0, length);
      if (length.value == 0) return const <int>[];
      final buffer = arena<Uint8>(length.value);
      final status = jackdaw_session_read(
        session,
        slot,
        buffer.cast(),
        length.value,
        length,
      );
      if (status != jackdaw_status.JACKDAW_OK.value) return const <int>[];
      return List<int>.of(buffer.asTypedList(length.value));
    });

/// Returns the message of the last failed generation on [session].
String readSessionError(Pointer<jackdaw_session> session) => using((arena) {
  final buffer = arena<Uint8>(1024);
  final length = arena<Int32>();
  jackdaw_session_error(session, buffer.cast(), 1024, length);
  return buffer.cast<Utf8>().toDartString(length: length.value);
});

/// Returns the statistics of the last finished generation on [session].
NativeStats readStats(Pointer<jackdaw_session> session) => using((arena) {
  final s = arena<jackdaw_session_stats>();
  jackdaw_session_get_stats(session, s);
  return NativeStats(
    promptTokens: s.ref.prompt_tokens,
    reusedTokens: s.ref.reused_tokens,
    generatedTokens: s.ref.generated_tokens,
    promptMs: s.ref.prompt_ms,
    firstTokenMs: s.ref.first_token_ms,
    totalMs: s.ref.generate_ms,
  );
});
