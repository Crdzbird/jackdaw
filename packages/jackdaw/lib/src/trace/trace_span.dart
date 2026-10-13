/// One timed operation in a trace.
abstract interface class TraceSpan {
  /// Attaches [value] under [key]; values should be JSON-compatible.
  void setAttribute(String key, Object? value);

  /// Finishes the span, recording [error] when the operation failed.
  void end({Object? error});
}
