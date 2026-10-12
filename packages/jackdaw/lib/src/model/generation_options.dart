/// Sampling settings for one model call.
final class GenerationOptions {
  /// Creates options; `null` values leave the provider default in place.
  const factory({double? temperature, int? maxOutputTokens}) =
      GenerationOptions._;

  const new _({this.temperature, this.maxOutputTokens});

  /// Sampling temperature.
  final double? temperature;

  /// Upper bound on generated tokens.
  final int? maxOutputTokens;
}
