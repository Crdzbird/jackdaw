part of 'session_record.dart';

/// A tool call finished with [result].
final class ToolResultRecord extends SessionRecord {
  /// Records [result].
  const factory(ToolResultPart result) = ToolResultRecord._;

  const new _(this.result) : super._();

  /// The finished call's result.
  final ToolResultPart result;
}
