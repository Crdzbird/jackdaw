import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_openai/wire.dart';

/// Builds wllama `createChatCompletion` options for [request].
///
/// The OpenAI body is reused for sampling settings, with wllama's
/// `max_tokens` name and streaming through [onData]. Messages, tools and
/// the response schema are rendered and constrained exactly as for the
/// native core: one prompt format and one grammar for every platform.
JSObject chatOptions(
  ModelRequest request,
  JSObject abortSignal,
  void Function(Object? chunk) onData,
) {
  final body = encodeChatRequest('local', request);
  ['stream_options', 'response_format', 'tools'].forEach(body.remove);
  final limit = body.remove('max_completion_tokens');
  final options =
      {
              ...body,
              'messages': [
                for (final (role, content) in localPrompt(request))
                  {'role': role, 'content': content},
              ],
              'max_tokens': ?limit,
              'grammar': ?_grammar(request),
            }.jsify()!
            as JSObject
        ..setProperty('abortSignal'.toJS, abortSignal)
        ..setProperty(
          'onData'.toJS,
          ((JSAny? chunk) => onData(chunk.dartify())).toJS,
        );
  return options;
}

String? _grammar(ModelRequest request) => switch ((
  request.tools,
  request.responseSchema,
)) {
  ([_, ...], final schema) => toolCallGrammar(request.tools, answer: schema),
  (_, final Schema schema) => GbnfCompiler().compile(schema),
  _ => null,
};
