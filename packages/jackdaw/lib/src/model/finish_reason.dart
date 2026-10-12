/// Why a model stopped producing output.
enum FinishReason {
  /// The model finished its answer.
  stop,

  /// The output token limit was reached.
  length,

  /// The model asked for tools to run.
  toolCalls,

  /// The provider withheld output for safety reasons.
  contentFilter,

  /// Any reason the provider reported that has no dedicated value.
  other,
}
