import 'dart:convert';

/// GBNF rules for the JSON primitives, keyed by rule name.
///
/// JSON is compact: no whitespace between tokens. A pretty-printed answer
/// takes about twice the tokens, so compact JSON is generated about twice
/// as fast and seldom runs out of tokens before it closes. Digit runs and
/// exponents are bounded so a model cannot loop inside one token class.
const Map<String, String> gbnfPrimitives = {
  'ws': 'ws ::= ""',
  'string':
      r'string ::= "\"" char* "\""'
      '\n'
      r'char ::= [^"\\\x7F\x00-\x1F] | "\\" (["\\/bfnrt] | "u" [0-9a-fA-F]{4})',
  'integer': 'integer ::= "-"? ("0" | [1-9] [0-9]{0,15})',
  'number':
      'number ::= "-"? ("0" | [1-9] [0-9]{0,15}) ("." [0-9]{1,15})? '
      '([eE] [-+]? [0-9]{1,3})?',
  'boolean': 'boolean ::= "true" | "false"',
  'value':
      'value ::= jobject | jarray | string | number | "true" | "false" | '
      '"null"\n'
      'jobject ::= "{" ws (string ws ":" ws value '
      '(ws "," ws string ws ":" ws value)*)? ws "}"\n'
      'jarray ::= "[" ws (value (ws "," ws value)*)? ws "]"',
};

/// [text] as a GBNF string literal that matches it exactly.
String gbnfText(String text) {
  final escaped = text
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n');
  return '"$escaped"';
}

/// [value] as a GBNF literal that matches its JSON string encoding.
String gbnfLiteral(String value) => gbnfText(jsonEncode(value));
