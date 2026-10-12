import 'package:jackdaw/src/schema/schema_violation.dart';

/// Thrown when a model's structured answer is not valid JSON or does not
/// match the requested schema.
final class StructuredOutputException implements Exception {
  /// Creates an exception for [text] with the problems found.
  const factory({
    required String text,
    required List<SchemaViolation> violations,
  }) = StructuredOutputException._;

  const new _({required this.text, required this.violations});

  /// The raw text the model produced.
  final String text;

  /// Why [text] was rejected; empty when it was not valid JSON at all.
  final List<SchemaViolation> violations;

  @override
  String toString() => violations.isEmpty
      ? 'StructuredOutputException: not valid JSON'
      : 'StructuredOutputException: ${violations.join('; ')}';
}
