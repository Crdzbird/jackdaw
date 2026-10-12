part of 'model_event.dart';

/// A complete block of reasoning produced by the model.
final class ReasoningEvent extends ModelEvent {
  /// Creates an event carrying [part].
  const factory(ReasoningPart part) = ReasoningEvent._;

  const new _(this.part) : super._();

  /// The reasoning.
  final ReasoningPart part;
}
