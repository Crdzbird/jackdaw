import 'package:jackdaw/src/schema/schema_violation.dart';

part 'any_of_schema.dart';
part 'array_schema.dart';
part 'boolean_schema.dart';
part 'integer_schema.dart';
part 'map_schema.dart';
part 'number_schema.dart';
part 'object_schema.dart';
part 'raw_schema.dart';
part 'string_schema.dart';
part 'summarized_schema.dart';
part 'union_schema.dart';

/// Writes a nested schema as a JSON Schema document.
typedef SchemaEncoder = Map<String, Object?> Function(Schema schema);

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

  /// Describes a JSON array of at least [minItems] and at most [maxItems]
  /// elements, the first matching [prefixItems] and the rest [items].
  const factory array({
    required Schema items,
    List<Schema> prefixItems,
    int minItems,
    int? maxItems,
    String? description,
  }) = ArraySchema;

  /// Describes a JSON object with any keys whose values match [values].
  const factory map({required Schema values, String? description}) = MapSchema;

  /// Describes JSON objects of several [variants], told apart by the
  /// value of their [discriminator] property.
  const factory union({
    required String discriminator,
    required Map<String, ObjectSchema> variants,
    String? description,
  }) = UnionSchema;

  /// Describes a value that matches at least one of [options].
  const factory anyOf(List<Schema> options, {String? description}) =
      AnyOfSchema;

  /// Holds values to [schema] while local prompts show [summary] instead.
  const factory summarized(Schema schema, {required String summary}) =
      SummarizedSchema;

  /// Passes the JSON Schema document [json] through unchanged.
  const factory raw(Map<String, Object?> json) = RawSchema;

  /// Explanation shown to the model.
  final String? description;

  /// The JSON Schema document for this schema.
  Map<String, Object?> toJson() => toJsonWith((schema) => schema.toJson());

  /// The JSON Schema document for this schema, with each nested schema
  /// written by [child], for example as a reference to a shared definition.
  Map<String, Object?> toJsonWith(SchemaEncoder child);

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
