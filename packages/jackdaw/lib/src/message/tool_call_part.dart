part of 'part.dart';

/// A request from the model to run a tool.
final class ToolCallPart extends Part {
  /// Creates a call to the tool [name] with decoded JSON [arguments].
  ///
  /// [arguments] holds the decoded JSON value, or the raw text when the
  /// model produced arguments that are not valid JSON.
  const factory({
    required String id,
    required String name,
    required Object? arguments,
  }) = ToolCallPart._;

  const new _({required this.id, required this.name, required this.arguments})
    : super._();

  /// Identifier that links this call to its [ToolResultPart].
  final String id;

  /// Name of the tool to run.
  final String name;

  /// Arguments chosen by the model.
  final Object? arguments;
}
