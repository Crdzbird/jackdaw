import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_openai/wire.dart';

/// Builds wllama `createChatCompletion` options for [request].
///
/// The OpenAI body is reused, with wllama's `max_tokens` name, a GBNF
/// grammar instead of `response_format`, and streaming through [onData].
JSObject chatOptions(
  ModelRequest request,
  JSObject abortSignal,
  void Function(Object? chunk) onData,
) {
  final body = encodeChatRequest('local', request)
    ..remove('stream_options')
    ..remove('response_format');
  final limit = body.remove('max_completion_tokens');
  final schema = request.responseSchema;
  final options =
      {
              ...body,
              'max_tokens': ?limit,
              if (schema != null) 'grammar': GbnfCompiler().compile(schema),
            }.jsify()!
            as JSObject
        ..setProperty('abortSignal'.toJS, abortSignal)
        ..setProperty(
          'onData'.toJS,
          ((JSAny? chunk) => onData(chunk.dartify())).toJS,
        );
  return options;
}
