import 'package:jackdaw/src/schema/schema.dart';

/// The JSON Schema document a local model reads for [schema], with each
/// [SummarizedSchema] written as its summary.
Map<String, Object?> promptSchemaJson(Schema schema) => switch (schema) {
  SummarizedSchema(:final summary) => {'description': summary},
  _ => schema.toJsonWith(promptSchemaJson),
};
