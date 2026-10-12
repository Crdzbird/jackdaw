part of 'model_event.dart';

/// A chunk of generated text.
final class TextDelta extends ModelEvent {
  /// Creates a delta holding [text].
  const factory(String text) = TextDelta._;

  const new _(this.text) : super._();

  /// The new text.
  final String text;
}
