import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';
import 'package:jackdaw_native/src/native/check_status.dart';

/// Embeds [texts] with the native embedder at [address], which produces
/// vectors of [dimensions] floats. Blocks; run it on a background isolate.
List<Float32List> embedTexts(int address, int dimensions, List<String> texts) =>
    using((arena) {
      final pointers = arena<Pointer<Char>>(texts.length);
      final lengths = arena<Int32>(texts.length);
      for (var i = 0; i < texts.length; i++) {
        final bytes = texts[i].toNativeUtf8(allocator: arena);
        pointers[i] = bytes.cast();
        lengths[i] = bytes.length;
      }
      final total = texts.length * dimensions;
      final out = arena<Float>(total);
      checkStatus(
        jackdaw_embedder_embed(
          Pointer.fromAddress(address),
          pointers,
          lengths,
          texts.length,
          out,
          total,
        ),
      );
      final flat = out.asTypedList(total);
      return [
        for (var i = 0; i < texts.length; i++)
          Float32List.fromList(
            Float32List.sublistView(flat, i * dimensions, (i + 1) * dimensions),
          ),
      ];
    });
