part of 'schema.dart';

/// A [schema] that local prompts describe with [summary] instead of its
/// full JSON Schema document.
///
/// Validation, grammars and [toJson] use the full schema. Only the text a
/// local model reads is replaced, so a schema too large for a small
/// model's context, such as one built from a UI catalog, can still hold
/// the model to every detail while the prompt explains it in a few lines.
final class SummarizedSchema extends Schema {
  /// Wraps [schema], to be described to local models as [summary].
  const factory(Schema schema, {required String summary}) = SummarizedSchema._;

  const new _(this.schema, {required this.summary}) : super._();

  /// The schema that validates and constrains.
  final Schema schema;

  /// What local prompts say about the schema.
  final String summary;

  @override
  Map<String, Object?> toJsonWith(SchemaEncoder child) =>
      schema.toJsonWith(child);

  @override
  List<SchemaViolation> validate(Object? value, {String path = r'$'}) =>
      schema.validate(value, path: path);
}
