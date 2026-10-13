import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/security/output_screen.dart';
import 'package:jackdaw/src/tool/tool.dart';
import 'package:jackdaw/src/tool/tool_spec.dart';
import 'package:jackdaw/src/trace/noop_tracer.dart';
import 'package:jackdaw/src/trace/trace_tool.dart';
import 'package:jackdaw/src/trace/tracer.dart';

/// The tools an agent may call, looked up by name.
final class ToolBox {
  /// Creates a tool box; tool names must be unique. Calls are traced with
  /// [tracer], including arguments and output when [content] is true, and
  /// successful results pass through [screen].
  factory(
    List<Tool<Object?>> tools, {
    Tracer tracer = const NoopTracer(),
    bool content = false,
    OutputScreen? screen,
  }) {
    final byName = {for (final tool in tools) tool.name: tool};
    if (byName.length != tools.length) {
      throw ArgumentError.value(tools, 'tools', 'tool names must be unique');
    }
    return ToolBox._(byName, tracer, content, screen);
  }

  const new _(this._tools, this._tracer, this._content, this._screen);

  final Map<String, Tool<Object?>> _tools;
  final Tracer _tracer;
  final bool _content;
  final OutputScreen? _screen;

  /// Descriptions of every tool, for the model request.
  List<ToolSpec> get specs => [for (final tool in _tools.values) tool.spec];

  /// The tool named [name], or `null` when none is registered.
  Tool<Object?>? operator [](String name) => _tools[name];

  /// Runs [call] on [tool] inside a trace span, then screens the result.
  Future<ToolResultPart> invoke(Tool<Object?> tool, ToolCallPart call) async {
    final result = await traceTool(_tracer, tool, call, content: _content);
    if (result.isError) return result;
    return _screen?.check(result) ?? result;
  }
}
