part of 'model_event.dart';

/// The last event of a model call.
final class FinishEvent extends ModelEvent {
  /// Creates the final event with [reason] and [usage].
  const factory({required FinishReason reason, Usage usage}) = FinishEvent._;

  const new _({required this.reason, this.usage = const Usage()}) : super._();

  /// Why the model stopped.
  final FinishReason reason;

  /// Tokens used by the call.
  final Usage usage;
}
