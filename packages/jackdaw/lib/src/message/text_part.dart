part of 'part.dart';

/// Plain text content.
final class TextPart extends Part {
  /// Creates a part holding [text].
  const factory(String text) = TextPart._;

  const new _(this.text) : super._();

  /// The text content.
  final String text;
}
