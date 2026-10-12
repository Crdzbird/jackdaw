part of 'model_event.dart';

/// A complete tool call requested by the model.
final class ToolCallEvent extends ModelEvent {
  /// Creates an event carrying [call].
  const factory(ToolCallPart call) = ToolCallEvent._;

  const new _(this.call) : super._();

  /// The requested call.
  final ToolCallPart call;
}
