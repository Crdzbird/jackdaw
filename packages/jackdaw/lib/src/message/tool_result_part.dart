part of 'part.dart';

/// The outcome of running a tool, sent back to the model.
final class ToolResultPart extends Part {
  /// Creates the result for the call identified by [callId].
  const factory({
    required String callId,
    required String name,
    required Object? output,
    bool isError,
  }) = ToolResultPart._;

  const new _({
    required this.callId,
    required this.name,
    required this.output,
    this.isError = false,
  }) : super._();

  /// Identifier of the [ToolCallPart] this result answers.
  final String callId;

  /// Name of the tool that ran.
  final String name;

  /// JSON-encodable output of the tool.
  final Object? output;

  /// Whether the tool failed; [output] then describes the failure.
  final bool isError;
}
