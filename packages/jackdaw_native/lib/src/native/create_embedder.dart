import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';
import 'package:jackdaw_native/src/native/check_status.dart';

/// Creates a native embedder on the model at [modelAddress] and returns its
/// address and vector size. Blocks; run it on a background isolate.
(int, int) createEmbedder(int modelAddress, int maxTokens, int threads) =>
    using((arena) {
      final out = arena<Pointer<jackdaw_embedder>>();
      final params = arena<jackdaw_embedder_params>();
      params.ref
        ..max_tokens = maxTokens
        ..threads = threads;
      checkStatus(
        jackdaw_embedder_create(Pointer.fromAddress(modelAddress), params, out),
      );
      return (out.value.address, jackdaw_embedder_dimensions(out.value));
    });
