import 'package:jackdaw/jackdaw.dart';

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
