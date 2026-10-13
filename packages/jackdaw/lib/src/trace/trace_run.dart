import 'dart:async';

import 'package:jackdaw/src/agent/agent_event.dart';
import 'package:jackdaw/src/trace/tracer.dart';

/// Streams [events] of session [sessionId] inside an `invoke_agent` span.
///
/// The span ends when the run finishes, fails or is cancelled, and records
/// why the agent stopped and the tokens it used.
Stream<AgentEvent> traceRun(
  Tracer tracer,
  String sessionId,
  Stream<AgentEvent> events,
) async* {
  final span = tracer.startSpan(
    'invoke_agent',
    attributes: {
      'gen_ai.operation.name': 'invoke_agent',
      'gen_ai.conversation.id': sessionId,
    },
  );
  Object? failure;
  try {
    yield* events.transform(
      StreamTransformer.fromHandlers(
        handleData: (event, sink) {
          if (event case AgentFinished(:final reason, :final usage)) {
            span
              ..setAttribute('jackdaw.stop_reason', reason.name)
              ..setAttribute('gen_ai.usage.input_tokens', usage.inputTokens)
              ..setAttribute('gen_ai.usage.output_tokens', usage.outputTokens);
          }
          sink.add(event);
        },
        handleError: (error, stack, sink) {
          failure = error;
          sink.addError(error, stack);
        },
      ),
    );
  } finally {
    span.end(error: failure);
  }
}
