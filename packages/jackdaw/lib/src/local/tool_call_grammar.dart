import 'dart:convert';

import 'package:jackdaw/src/grammar/gbnf_compiler.dart';
import 'package:jackdaw/src/local/tool_call_format.dart';
import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/tool/tool_spec.dart';

/// A GBNF grammar that lets a local model either call [tools], with
/// arguments that match each tool's schema, or answer.
///
/// The answer is free text that does not start with `<`, or JSON that
/// matches [answer] when given. Up to [maxCalls] calls are allowed in one
/// turn; the default of one stops small models from repeating a call, and
/// the agent still runs several calls one turn after another.
///
/// Grammars are kept for the last few combinations of tools, so a turn
/// that offers the same tools as an earlier one does not compile again.
String toolCallGrammar(
  List<ToolSpec> tools, {
  Schema? answer,
  int maxCalls = 1,
}) {
  RangeError.checkValueInInterval(maxCalls, 1, 64, 'maxCalls');
  final key = [
    maxCalls,
    _id(answer),
    for (final tool in tools) '${tool.name}:${_id(tool.input)}',
  ].join('|');
  final grammar = _recent.remove(key) ?? _compile(tools, answer, maxCalls);
  _recent[key] = grammar;
  if (_recent.length > 16) _recent.remove(_recent.keys.first);
  return grammar;
}

final Map<String, String> _recent = {};
final Expando<int> _ids = Expando();
int _next = 0;

int _id(Object? schema) => schema == null ? -1 : _ids[schema] ??= _next++;

String _compile(List<ToolSpec> tools, Schema? answer, int maxCalls) {
  final compiler = GbnfCompiler();
  String callOf(ToolSpec tool) {
    final head = '$toolCallOpen{"name":${jsonEncode(tool.name)},"arguments":';
    const tail = '}$toolCallClose';
    return '${GbnfCompiler.text(head)} ${compiler.rule(tool.input)} '
        '${GbnfCompiler.text(tail)}';
  }

  final calls = [for (final tool in tools) callOf(tool)];
  final call = compiler.define(calls.join(' | '));
  final reply = answer == null
      ? compiler.define('[^<] .*')
      : compiler.rule(answer);
  final more = maxCalls > 1 ? ' ("\\n" $call){0,${maxCalls - 1}}' : '';
  return compiler.render('$call$more | $reply');
}
