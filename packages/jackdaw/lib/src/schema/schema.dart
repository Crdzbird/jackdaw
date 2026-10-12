import 'package:jackdaw/src/schema/schema_violation.dart';

part 'array_schema.dart';
part 'boolean_schema.dart';
part 'integer_schema.dart';
part 'number_schema.dart';
part 'object_schema.dart';
part 'string_schema.dart';

/// A JSON Schema subset that describes tool inputs and structured output.
///
/// Schemas are built in code, need no code generation, serialize with
/// [toJson] for providers, and check values offline with [validate].
sealed class Schema {
  const new _({this.description});

  /// Describes a JSON object with named [properties].
  const factory object({
    required Map<String, Schema> properties,
    List<String> required,
    bool additionalProperties,
    String? description,
  }) = ObjectSchema;

  /// Describes a JSON string, optionally limited to [enumValues].
  const factory string({List<String>? enumValues, String? description}) =
      StringSchema;

  /// Describes a JSON number without a fractional part.
  const factory integer({String? description}) = IntegerSchema;

  /// Describes any JSON number.
  const factory number({String? description}) = NumberSchema;

  /// Describes a JSON boolean.
  const factory boolean({String? description}) = BooleanSchema;

  /// Describes a JSON array whose elements match [items].
  const factory array({required Schema items, String? description}) =
      ArraySchema;

  /// Explanation shown to the model.
  final String? description;

  /// The JSON Schema document for this schema.
  Map<String, Object?> toJson();

  /// Returns every violation of this schema by [value], or none when valid.
  List<SchemaViolation> validate(Object? value, {String path = r'$'});

  Map<String, Object?> _base(String type) => {
    'type': type,
    if (description != null) 'description': description,
  };

  List<SchemaViolation> _expect(bool ok, String path, String what) => [
    if (!ok) SchemaViolation(path, 'expected $what'),
  ];
}
