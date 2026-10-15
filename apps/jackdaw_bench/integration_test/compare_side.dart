import 'package:flutter/widgets.dart';

/// One renderer in the comparison of claim C14: it takes A2UI v1.0
/// messages, after any conversion done ahead of time, and draws the
/// surface `bench`.
abstract interface class CompareSide {
  /// The renderer's name in the report.
  String get name;

  /// [message] converted for this renderer, outside the timed part.
  List<Map<String, Object?>> prepare(Map<String, Object?> message);

  /// Applies messages from [prepare].
  void apply(List<Map<String, Object?>> messages);

  /// The surface as a widget.
  Widget view();

  /// Frees the renderer.
  void dispose();
}
