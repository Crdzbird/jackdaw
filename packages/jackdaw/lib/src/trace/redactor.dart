import 'package:jackdaw/src/security/secret.dart';

/// Removes secrets from text before it leaves the app in a trace or log.
///
/// Values of the given [Secret]s are always removed. Common credential
/// shapes (API keys of major providers, bearer tokens, AWS access keys,
/// GitHub tokens) are removed too, as a safety net for secrets that were
/// never registered.
final class Redactor {
  /// Creates a redactor for [secrets].
  factory(Iterable<Secret> secrets) = Redactor._;

  new _(Iterable<Secret> secrets)
    : _secrets = [for (final s in secrets) s.reveal()]
          .where((value) => value.isNotEmpty)
          .toList();

  final List<String> _secrets;

  static final RegExp _patterns = RegExp(
    '(sk-[A-Za-z0-9_-]{16,})|(AIza[0-9A-Za-z_-]{30,})|(AKIA[0-9A-Z]{16})'
    '|(gh[pousr]_[A-Za-z0-9]{30,})'
    r'|(Bearer\s+[A-Za-z0-9._~+/=-]{16,})',
  );

  /// Returns [value] with secrets replaced, walking maps and lists.
  Object? redact(Object? value) => switch (value) {
    final String text => _text(text),
    final Map<Object?, Object?> map => {
      for (final MapEntry(:key, :value) in map.entries) key: redact(value),
    },
    final List<Object?> list => [for (final item in list) redact(item)],
    _ => value,
  };

  String _text(String text) {
    var out = text;
    for (final secret in _secrets) {
      out = out.replaceAll(secret, '[redacted]');
    }
    return out.replaceAll(_patterns, '[redacted]');
  }
}
