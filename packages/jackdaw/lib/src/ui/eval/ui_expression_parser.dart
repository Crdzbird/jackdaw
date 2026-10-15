import 'package:jackdaw/src/ui/eval/ui_eval_exception.dart';

/// Reads the expressions inside `formatString` placeholders as A2UI
/// values: a path becomes `{"@path": ...}`, a call `{"@call": ...}` with
/// named arguments, and a quoted string, number, `true`, `false` or `null`
/// stays a literal. An argument may itself be a `${...}` placeholder.
final class UiExpressionParser {
  /// Creates a parser of [source] starting at [at].
  factory(String source, [int at]) = UiExpressionParser._;

  new _(this.source, [this.at = 0]);

  /// The text being read.
  final String source;

  /// The position of the next character to read.
  int at;

  static final RegExp _name = RegExp('[A-Za-z_@][A-Za-z0-9_]*');
  static final RegExp _number = RegExp(r'-?\d+(\.\d+)?([eE][-+]?\d+)?');
  static final RegExp _path = RegExp(r'[^\s,(){}:]+');

  /// Reads one expression and returns it as an A2UI value.
  Object? expression() {
    _skip();
    if (source.startsWith(r'${', at)) {
      at += 2;
      final inner = expression();
      expect('}');
      return inner;
    }
    final quote = at < source.length ? source[at] : '';
    if (quote == "'" || quote == '"') return _quoted(quote);
    if (_take(_number) case final number?) return num.parse(number);
    final name = _peek(_name);
    if (name != null && source.startsWith('(', at + name.length)) {
      at += name.length + 1;
      return {'@call': name, 'args': _args()};
    }
    if (_take(_path) case final path?) {
      return switch (path) {
        'true' => true,
        'false' => false,
        'null' => null,
        _ => {'@path': path},
      };
    }
    throw UiEvalException(
      'EXPRESSION_ERROR',
      'Cannot read ${source.substring(at)}.',
    );
  }

  Map<String, Object?> _args() {
    final args = <String, Object?>{};
    _skip();
    while (!source.startsWith(')', at)) {
      _skip();
      final key = _take(_name) ?? '';
      expect(key.isEmpty ? 'an argument name' : ':');
      args[key] = expression();
      _skip();
      if (source.startsWith(',', at)) at++;
      if (at >= source.length) expect(')');
    }
    at++;
    return args;
  }

  String _quoted(String quote) {
    final end = source.indexOf(quote, at + 1);
    if (end < 0) throw UiEvalException('EXPRESSION_ERROR', 'Unclosed $quote.');
    final text = source.substring(at + 1, end);
    at = end + 1;
    return text;
  }

  String? _peek(RegExp pattern) => pattern.matchAsPrefix(source, at)?[0];

  String? _take(RegExp pattern) {
    final match = _peek(pattern);
    if (match != null) at += match.length;
    return match;
  }

  void _skip() {
    while (at < source.length && source[at].trim().isEmpty) {
      at++;
    }
  }

  /// Requires [text] next, after optional spaces.
  void expect(String text) {
    _skip();
    if (!source.startsWith(text, at)) {
      throw UiEvalException('EXPRESSION_ERROR', 'Expected $text at $at.');
    }
    at += text.length;
  }
}
