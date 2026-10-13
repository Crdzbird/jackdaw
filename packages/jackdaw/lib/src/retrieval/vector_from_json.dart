import 'dart:typed_data';

/// Reads a JSON list of numbers as a vector; anything else fails with
/// [FormatException], so a malformed provider answer is never indexed.
Float32List vectorFromJson(Object? json) {
  if (json is! List || json.any((x) => x is! num)) {
    throw const FormatException('expected a list of numbers');
  }
  return Float32List.fromList([for (final x in json) (x as num).toDouble()]);
}
