import 'dart:async';

import 'package:jackdaw/src/context/message_content.dart';
import 'package:jackdaw/src/model/language_model.dart';
import 'package:jackdaw/src/model/model_event.dart';
import 'package:jackdaw/src/model/model_request.dart';
import 'package:jackdaw/src/trace/trace_span.dart';
import 'package:jackdaw/src/trace/tracer.dart';

/// Wraps a [LanguageModel] so each call becomes a `chat` span.
///
/// Token usage and the finish reason are always recorded. Prompts and
/// answers are recorded only when [content] is true.
final class TracedModel implements LanguageModel {
  /// Traces calls to [inner] with [tracer].
  const factory(LanguageModel inner, Tracer tracer, {bool content}) =
      TracedModel._;

  const new _(this._inner, this._tracer, {this.content = false});

  final LanguageModel _inner;
  final Tracer _tracer;

  /// Whether prompts and answers are attached to spans.
  final bool content;

  @override
  String get id => _inner.id;

  @override
  Stream<ModelEvent> generate(ModelRequest request) {
    final controller = StreamController<ModelEvent>(sync: true);
    final output = StringBuffer();
    TraceSpan? span;
    void end({Object? error}) {
      span?.end(error: error);
      span = null;
    }

    controller.onListen = () {
      span = _tracer.startSpan(
        'chat $id',
        attributes: {
          'gen_ai.operation.name': 'chat',
          'gen_ai.request.model': id,
          if (content)
            'gen_ai.input.messages': [
              for (final m in request.messages)
                {'role': m.role.name, 'content': messageContent(m)},
            ],
        },
      );
      final sub = _inner
          .generate(request)
          .listen(
            (event) {
              _observe(event, span, output);
              controller.add(event);
            },
            onError: (Object error, StackTrace stack) {
              end(error: error);
              controller.addError(error, stack);
            },
            onDone: () {
              if (content) span?.setAttribute('gen_ai.output.text', '$output');
              end();
              unawaited(controller.close());
            },
          );
      controller
        ..onPause = sub.pause
        ..onResume = sub.resume
        ..onCancel = () {
          end();
          return sub.cancel();
        };
    };
    return controller.stream;
  }

  void _observe(ModelEvent event, TraceSpan? span, StringBuffer output) {
    if (event is TextDelta && content) output.write(event.text);
    if (event is! FinishEvent) return;
    span
      ?..setAttribute('gen_ai.response.finish_reasons', [event.reason.name])
      ..setAttribute('gen_ai.usage.input_tokens', event.usage.inputTokens)
      ..setAttribute('gen_ai.usage.output_tokens', event.usage.outputTokens);
  }
}
