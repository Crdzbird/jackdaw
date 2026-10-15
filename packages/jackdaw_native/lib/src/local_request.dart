import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/src/native/native_generate_options.dart';

/// The native options for [request]: its sampling settings and the grammar
/// that holds the model to it.
NativeGenerateOptions localOptions(ModelRequest request) =>
    NativeGenerateOptions(
      temperature: request.options.temperature ?? 0,
      maxTokens: request.options.maxOutputTokens ?? 0,
      grammar: localGrammar(request),
    );

/// The grammar that holds a local model to [request]: tool calls or an
/// answer when it offers tools, JSON matching its response schema when it
/// asks for one, and none for free text. Grammars come from caches, so a
/// schema is compiled once.
String? localGrammar(ModelRequest request) =>
    switch ((request.tools.isEmpty, request.responseSchema)) {
      (false, final schema) => toolCallGrammar(request.tools, answer: schema),
      (true, final Schema schema) => gbnfGrammar(schema),
      (true, null) => null,
    };
