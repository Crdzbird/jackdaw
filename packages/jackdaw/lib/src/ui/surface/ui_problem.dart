import 'package:jackdaw/src/ui/schema/ui_message_schema.dart';
import 'package:jackdaw/src/ui/surface/ui_problem_code.dart';

/// Something wrong with the UI an agent sent, reported back to it.
final class UiProblem {
  /// Creates a problem with [code] on [surfaceId] at [path]. A [warning]
  /// does not keep the UI from being shown.
  const factory(
    UiProblemCode code,
    String message, {
    String? surfaceId,
    String path,
    bool warning,
  }) = UiProblem._;

  const new _(
    this.code,
    this.message, {
    this.surfaceId,
    this.path = '',
    this.warning = false,
  });

  /// What kind of problem it is.
  final UiProblemCode code;

  /// One sentence on what is wrong, for the model to correct.
  final String message;

  /// The surface the problem is on, when known.
  final String? surfaceId;

  /// Whether the UI can still be shown, such as when a component is only
  /// left out because nothing refers to it.
  final bool warning;

  /// A JSON Pointer to the offending field, or empty for the whole message.
  final String path;

  /// The problem as an A2UI v1.0 renderer-to-agent `error` message.
  Map<String, Object?> toJson() => {
    'version': uiProtocolVersion,
    'error': {
      'code': code.wire,
      'surfaceId': ?surfaceId,
      'path': path,
      'message': message,
    },
  };

  @override
  String toString() => '${code.wire} ${surfaceId ?? '-'} $path: $message';
}
