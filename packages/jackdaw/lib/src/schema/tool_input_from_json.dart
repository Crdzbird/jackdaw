import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/schema/schema_from_json.dart';

/// Reads [json] as the arguments schema of a tool. A document that is not
/// a plain object schema becomes an object that accepts any keys, with the
/// document's description.
ObjectSchema toolInputFromJson(Map<String, Object?> json) =>
    switch (schemaFromJson(json)) {
      final ObjectSchema schema => schema,
      _ => ObjectSchema(
        properties: const {},
        additionalProperties: true,
        description: json['description'] is String
            ? json['description']! as String
            : null,
      ),
    };
