import 'package:jackdaw/src/tool/tool.dart';
import 'package:jackdaw/src/tool/tool_spec.dart';

/// The tools an agent may call, looked up by name.
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

  /// The tool named [name], or `null` when none is registered.
  Tool<Object?>? operator [](String name) => _tools[name];
}
