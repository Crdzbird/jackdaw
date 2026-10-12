import 'dart:async';

/// Passes events through and, once the source finishes, emits [tail].
///
/// [tail] runs only after every source event was seen, which suits decoders
/// that flush buffered state at the end. Cancelling the result cancels the
/// source immediately.
StreamTransformer<T, T> appendOnDone<T>(Iterable<T> Function() tail) =>
    StreamTransformer<T, T>.fromHandlers(
      handleDone: (sink) {
        tail().forEach(sink.add);
        sink.close();
      },
    );
