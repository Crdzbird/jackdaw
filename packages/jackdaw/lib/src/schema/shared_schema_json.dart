import 'package:jackdaw/src/schema/schema.dart';

/// The JSON Schema document for [schema] with every composite schema used
/// more than once written once under `$defs` and referred to by `$ref`.
///
/// Schemas built from catalogs reuse the same parts many times; written
/// out in full they can run to megabytes, written this way they stay small.
/// Sharing follows identity, so equal schemas built separately are still
/// written twice.
Map<String, Object?> sharedSchemaJson(Schema schema) {
  final uses = Map<Schema, int>.identity();
  void visit(Schema node) {
    uses[node] = (uses[node] ?? 0) + 1;
    if (uses[node] == 1) {
      node.toJsonWith((child) {
        visit(child);
        return const {};
      });
    }
  }

  visit(schema);
  final names = Map<Schema, String>.identity();
  for (final MapEntry(:key, :value) in uses.entries) {
    if (value > 1 && _composite(key)) names[key] = 'd${names.length}';
  }
  Map<String, Object?> encode(Schema node) => switch (names[node]) {
    final name? => {r'$ref': '#/\$defs/$name'},
    null => node.toJsonWith(encode),
  };
  return {
    ...schema.toJsonWith(encode),
    if (names.isNotEmpty)
      r'$defs': {
        for (final MapEntry(:key, :value) in names.entries)
          value: key.toJsonWith(encode),
      },
  };
}

bool _composite(Schema schema) => switch (schema) {
  ObjectSchema() ||
  ArraySchema() ||
  MapSchema() ||
  AnyOfSchema() ||
  UnionSchema() => true,
  _ => false,
};
