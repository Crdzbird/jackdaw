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
/// turn.
String toolCallGrammar(
  List<ToolSpec> tools, {
  Schema? answer,
  int maxCalls = 8,
}) {
  final compiler = GbnfCompiler();
  String callOf(ToolSpec tool) {
    final head =
        '$toolCallOpen{"name": ${jsonEncode(tool.name)}, "arguments": ';
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
