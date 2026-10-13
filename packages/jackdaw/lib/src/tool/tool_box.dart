import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/tool/tool.dart';
import 'package:jackdaw/src/tool/tool_spec.dart';
import 'package:jackdaw/src/trace/noop_tracer.dart';
import 'package:jackdaw/src/trace/trace_tool.dart';
import 'package:jackdaw/src/trace/tracer.dart';

/// The tools an agent may call, looked up by name.
final class ToolBox {
  /// Creates a tool box; tool names must be unique. Calls are traced with
  /// [tracer], including arguments and output when [content] is true.
  factory(
    List<Tool<Object?>> tools, {
    Tracer tracer = const NoopTracer(),
    bool content = false,
  }) {
    final byName = {for (final tool in tools) tool.name: tool};
    if (byName.length != tools.length) {
      throw ArgumentError.value(tools, 'tools', 'tool names must be unique');
    }
    return ToolBox._(byName, tracer, content);
  }

  const new _(this._tools, this._tracer, this._content);

  final Map<String, Tool<Object?>> _tools;
  final Tracer _tracer;
  final bool _content;

  /// Descriptions of every tool, for the model request.
  List<ToolSpec> get specs => [for (final tool in _tools.values) tool.spec];

  /// The tool named [name], or `null` when none is registered.
  Tool<Object?>? operator [](String name) => _tools[name];

  /// Runs [call] on [tool] inside a trace span.
  Future<ToolResultPart> invoke(Tool<Object?> tool, ToolCallPart call) =>
      traceTool(_tracer, tool, call, content: _content);
}
