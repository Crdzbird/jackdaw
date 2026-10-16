import 'package:web/web.dart' as web;

/// One renderer in the browser comparison: it takes A2UI v1.0 messages,
/// after any conversion done ahead of time, and draws the surface `bench`
/// into a host element.
abstract interface class WebSide {
  /// The renderer's name in the report.
  String get name;

  /// [message] converted for this renderer, outside the timed part.
  List<Object?> prepare(Map<String, Object?> message);

  /// Gets ready to draw the surface in [host] and returns which of the
  /// prepared [create] messages are left to time.
  List<Object?> mount(web.HTMLElement host, List<Object?> create);

  /// Applies prepared messages.
  void apply(List<Object?> messages);

  /// Stops drawing.
  void dispose();
}
