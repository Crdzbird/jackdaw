import 'package:jackdaw/src/message/part.dart';

/// Checks what a tool returned before the model reads it.
abstract interface class OutputScreen {
  /// Returns [result] as the model should see it: unchanged, annotated, or
  /// replaced by an error.
  ToolResultPart check(ToolResultPart result);
}
