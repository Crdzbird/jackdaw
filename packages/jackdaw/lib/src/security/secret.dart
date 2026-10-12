/// A sensitive value, such as an API key, that never prints itself.
///
/// [toString] is redacted so the value cannot leak into logs, traces or
/// error messages by accident. Call [reveal] only where the raw value is
/// needed, such as an authorization header.
final class Secret {
  /// Wraps [value].
  const factory(String value) = Secret._;

  const new _(this._value);

  final String _value;

  /// Returns the raw value.
  String reveal() => _value;

  @override
  String toString() => 'Secret(redacted)';
}
