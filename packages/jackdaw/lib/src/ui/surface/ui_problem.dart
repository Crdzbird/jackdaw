import 'package:jackdaw/src/ui/schema/ui_message_schema.dart';
import 'package:jackdaw/src/ui/surface/ui_problem_code.dart';

/// Something wrong with the UI an agent sent, reported back to it.
final class UiProblem {
  /// Creates a problem with [code] on [surfaceId] at [path].
  const factory(
    UiProblemCode code,
    String message, {
    String? surfaceId,
    String path,
  }) = UiProblem._;

  const new _(this.code, this.message, {this.surfaceId, this.path = ''});

  /// What kind of problem it is.
  final UiProblemCode code;

  /// One sentence on what is wrong, for the model to correct.
  final String message;

  /// The surface the problem is on, when known.
  final String? surfaceId;

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
