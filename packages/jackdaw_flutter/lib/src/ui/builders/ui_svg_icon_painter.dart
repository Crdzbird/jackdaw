import 'package:flutter/rendering.dart';

/// Paints [path] filled with [color], scaled to fit the canvas the way a
/// 24 by 24 icon is drawn.
final class UiSvgIconPainter extends CustomPainter {
  /// Paints [path] in [color].
  const factory(Path path, Color color) = UiSvgIconPainter._;

  const new _(this.path, this.color);

  /// The icon's outline, in a 24 by 24 box.
  final Path path;

  /// The fill colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = path.getBounds();
    final extent = [
      24.0,
      bounds.right,
      bounds.bottom,
    ].reduce((a, b) => a > b ? a : b);
    canvas
      ..scale(size.shortestSide / extent)
      ..drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(UiSvgIconPainter old) =>
      old.path != path || old.color != color;
}
