import 'package:jackdaw/src/trace/noop_tracer.dart';
import 'package:jackdaw/src/trace/redacting_tracer.dart';
import 'package:jackdaw/src/trace/redactor.dart';
import 'package:jackdaw/src/trace/tracer.dart';

/// Returns [tracer] wrapped so common credential shapes are always removed,
/// unless it already redacts or records nothing.
Tracer redactByDefault(Tracer tracer) => switch (tracer) {
  NoopTracer() || RedactingTracer() => tracer,
  _ => RedactingTracer(tracer, Redactor(const [])),
};
