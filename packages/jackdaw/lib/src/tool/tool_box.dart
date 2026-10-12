import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/tool/tool.dart';
import 'package:jackdaw/src/tool/tool_spec.dart';

/// Looks up tools by name and runs batches of calls concurrently.
final class ToolBox {
  /// Creates a tool box; tool names must be unique.
  factory(List<Tool<Object?>> tools) {
    final byName = {for (final tool in tools) tool.name: tool};
    if (byName.length != tools.length) {
      throw ArgumentError.value(tools, 'tools', 'tool names must be unique');
    }
    return ToolBox._(byName);
  }

  const new _(this._tools);

  final Map<String, Tool<Object?>> _tools;

  /// Descriptions of every tool, for the model request.
  List<ToolSpec> get specs => [for (final tool in _tools.values) tool.spec];

  /// Runs every call at once and returns results in call order.
  Future<List<ToolResultPart>> runAll(List<ToolCallPart> calls) =>
      Future.wait(calls.map(run));

  /// Runs [call], reporting unknown tools to the model as an error.
  Future<ToolResultPart> run(ToolCallPart call) async {
    final tool = _tools[call.name];
    if (tool == null) {
      return ToolResultPart(
        callId: call.id,
        name: call.name,
        output: {'error': 'unknown tool ${call.name}'},
        isError: true,
      );
    }
    return await tool.invoke(call);
  }
}
