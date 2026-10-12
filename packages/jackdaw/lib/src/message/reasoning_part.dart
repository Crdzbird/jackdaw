part of 'part.dart';

/// Reasoning the model produced before answering.
///
/// [text] is a readable summary when the provider exposes one, and may be
/// empty. [data] is the provider's own record of the reasoning, such as a
/// signed thinking block. Providers require it back unchanged on later
/// turns, so it is replayed only to the [provider] that produced it.
final class ReasoningPart extends Part {
  /// Creates reasoning produced by [provider].
  const factory({
    required String provider,
    String text,
    Map<String, Object?> data,
  }) = ReasoningPart._;

  const new _({required this.provider, this.text = '', this.data = const {}})
    : super._();

  /// Name of the provider that produced the reasoning, such as `anthropic`.
  final String provider;

  /// Readable summary; may be empty.
  final String text;

  /// Provider payload to send back unchanged.
  final Map<String, Object?> data;
}
