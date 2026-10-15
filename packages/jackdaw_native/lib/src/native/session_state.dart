import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';
import 'package:jackdaw_native/src/native/check_status.dart';

/// Writes the state of the session at [address] to [path] on another
/// isolate, so the file write never blocks the caller.
Future<void> saveSessionState(int address, String path) => Isolate.run(
  () => using((arena) {
    checkStatus(
      jackdaw_session_save(
        Pointer<jackdaw_session>.fromAddress(address),
        path.toNativeUtf8(allocator: arena).cast(),
      ),
    );
  }),
);

/// Loads the state at [path] into the session at [address] on another
/// isolate and returns the number of tokens restored, or 0 when the file
/// is missing or belongs to another model.
Future<int> loadSessionState(int address, String path) => Isolate.run(
  () => using((arena) {
    final count = arena<Int32>();
    final status = jackdaw_session_load(
      Pointer<jackdaw_session>.fromAddress(address),
      path.toNativeUtf8(allocator: arena).cast(),
      count,
    );
    if (status == jackdaw_status.JACKDAW_ERR_IO.value) return 0;
    checkStatus(status);
    return count.value;
  }),
);
