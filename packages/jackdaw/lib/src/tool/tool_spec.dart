import 'package:jackdaw/src/schema/schema.dart';

/// What a model is told about a tool: its name, purpose and input shape.
final class ToolSpec {
  /// Creates a tool description.
  const factory({
    required String name,
    required String description,
    required ObjectSchema input,
  }) = ToolSpec._;

  const new _({
    required this.name,
    required this.description,
    required this.input,
  });

  /// Unique name the model uses to call the tool.
  final String name;

  /// When and why the model should use the tool.
  final String description;

  /// Schema of the arguments object.
  final ObjectSchema input;
}
