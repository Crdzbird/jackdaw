part of 'schema.dart';

/// Schema for a value described by a JSON Schema document that the typed
/// schemas cannot express, such as one using `anyOf` or `$ref`.
///
/// [toJson] returns the document unchanged, so providers see every
/// constraint. [validate] accepts any value and constrained decoding only
/// guarantees well-formed JSON, so prefer the typed schemas where they fit.
final class RawSchema extends Schema {
  /// Wraps the JSON Schema document [json].
  const factory(Map<String, Object?> json) = RawSchema._;

  const new _(this.json) : super._();

  /// The JSON Schema document.
  final Map<String, Object?> json;

  @override
  Map<String, Object?> toJson() => json;

  @override
  List<SchemaViolation> validate(Object? value, {String path = r'$'}) =>
      const [];
}
