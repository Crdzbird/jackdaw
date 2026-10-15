import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/schema/schema_from_json.dart';

/// Reads an array document with optional `prefixItems`, `minItems` and
/// `maxItems`, or keeps it whole as a [RawSchema] when they are malformed.
Schema arrayFromJson(Map<String, Object?> json, String? text) {
  final min = json['minItems'] ?? 0;
  final max = json['maxItems'];
  final prefix = json['prefixItems'] ?? const <Object?>[];
  if (min is! int ||
      min < 0 ||
      (max != null && max is! int) ||
      prefix is! List ||
      prefix.any((p) => p is! Map<String, Object?>)) {
    return RawSchema(json);
  }
  final items = json['items']! as Map<String, Object?>;
  return ArraySchema(
    items: schemaFromJson(items),
    prefixItems: [
      for (final p in prefix) schemaFromJson(p! as Map<String, Object?>),
    ],
    minItems: min,
    maxItems: max as int?,
    description: text,
  );
}
