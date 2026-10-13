import 'package:jackdaw/src/trace/trace_span.dart';

/// Receives the spans an agent produces for runs, model calls and tools.
///
/// Attribute names follow the OpenTelemetry GenAI conventions where one
/// exists, such as `gen_ai.request.model` and `gen_ai.usage.input_tokens`.
abstract interface class Tracer {
  /// Starts a span named [name] with initial [attributes].
  TraceSpan startSpan(String name, {Map<String, Object?> attributes});
}
