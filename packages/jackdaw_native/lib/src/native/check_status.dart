import 'package:ffi/ffi.dart';
import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';
import 'package:jackdaw_native/src/native/native_exception.dart';

/// Throws a [NativeException] unless [status] is `JACKDAW_OK`.
///
/// Must run on the same thread as the failing call, because the message is
/// thread-local in the native core.
void checkStatus(int status) {
  if (status == jackdaw_status.JACKDAW_OK.value) return;
  throw nativeError(status);
}

/// Throws unless the loaded library speaks the ABI these bindings target.
void checkAbi() => checkAbiVersion(jackdaw_abi_version());

/// Throws unless [loaded] equals the ABI version of these bindings.
void checkAbiVersion(int loaded) {
  if (loaded != JACKDAW_ABI_VERSION) {
    throw StateError('libjackdaw ABI $loaded, expected $JACKDAW_ABI_VERSION');
  }
}

/// Builds the exception for a failed call made on this thread.
NativeException nativeError(int status) =>
    NativeException(status, jackdaw_last_error().cast<Utf8>().toDartString());
