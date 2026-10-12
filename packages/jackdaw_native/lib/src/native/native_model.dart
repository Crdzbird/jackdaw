import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';
import 'package:jackdaw_native/src/native/check_status.dart';

/// A GGUF model loaded into native memory.
final class NativeModel {
  new _(this.pointer);

  /// Loads the model at [path] on a background isolate.
  ///
  /// [gpuLayers] below zero offloads every layer when a GPU backend exists.
  static Future<NativeModel> load(
    String path, {
    int gpuLayers = -1,
    bool mmap = true,
  }) async {
    final address = await Isolate.run(
      () => using((arena) {
        checkAbi();
        final out = arena<Pointer<jackdaw_model>>();
        final params = arena<jackdaw_model_params>();
        params.ref
          ..gpu_layers = gpuLayers
          ..use_mmap = mmap ? 1 : 0;
        final nativePath = path.toNativeUtf8(allocator: arena).cast<Char>();
        checkStatus(jackdaw_model_load(nativePath, params, out));
        return out.value.address;
      }),
    );
    return NativeModel._(Pointer.fromAddress(address));
  }

  /// The native handle; valid until [dispose].
  final Pointer<jackdaw_model> pointer;

  /// Number of tokens [text] occupies, using the model's own vocabulary.
  int countTokens(String text) => using((arena) {
    final bytes = text.toNativeUtf8(allocator: arena);
    final count = arena<Int32>();
    final status = jackdaw_model_tokenize(
      pointer,
      bytes.cast(),
      bytes.length,
      0,
      nullptr,
      0,
      count,
    );
    if (status != jackdaw_status.JACKDAW_ERR_BUFFER_TOO_SMALL.value) {
      checkStatus(status);
    }
    return count.value;
  });

  /// Renders [messages], given as role and content pairs, with the model's
  /// chat template, ending with the assistant turn opener.
  String applyTemplate(List<(String, String)> messages) => using((arena) {
    final chat = arena<jackdaw_chat_message>(messages.length);
    for (var i = 0; i < messages.length; i++) {
      final (role, content) = messages[i];
      chat[i]
        ..role = role.toNativeUtf8(allocator: arena).cast()
        ..content = content.toNativeUtf8(allocator: arena).cast();
    }
    final length = arena<Int32>();
    final count = messages.length;
    jackdaw_model_apply_template(pointer, chat, count, 1, nullptr, 0, length);
    final buffer = arena<Uint8>(length.value);
    checkStatus(
      jackdaw_model_apply_template(
        pointer,
        chat,
        count,
        1,
        buffer.cast(),
        length.value,
        length,
      ),
    );
    return buffer.cast<Utf8>().toDartString(length: length.value);
  });

  /// Frees the model. Every session using it must be disposed first.
  void dispose() => jackdaw_model_free(pointer);
}
