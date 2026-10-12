import 'dart:js_interop';

/// The browser's `AbortController`.
@JS('AbortController')
extension type AbortController._(JSObject _) implements JSObject {
  /// Creates a controller whose [signal] has not been aborted.
  external factory();

  /// Signal handed to the operation that can be aborted.
  external JSObject get signal;

  /// Aborts the operation listening to [signal].
  external void abort();
}
