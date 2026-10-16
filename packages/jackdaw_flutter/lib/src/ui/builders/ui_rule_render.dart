part of 'ui_rule.dart';

typedef _RuleStyle = ({
  double space,
  double thickness,
  double indent,
  double endIndent,
  Color color,
  TextDirection direction,
});

final class _RenderUiRule extends RenderBox {
  new(this._style);

  _RuleStyle _style;

  void restyle(_RuleStyle value) {
    if (value == _style) return;
    final resized = value.space != _style.space;
    _style = value;
    if (resized) markNeedsLayout();
    markNeedsPaint();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    Size(constraints.hasBoundedWidth ? constraints.maxWidth : 0, _style.space),
  );

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
  }

  @override
  double computeMinIntrinsicHeight(double width) => _style.space;

  @override
  double computeMaxIntrinsicHeight(double width) => _style.space;

  @override
  void paint(PaintingContext context, Offset offset) {
    final rtl = _style.direction == TextDirection.rtl;
    final left = rtl ? _style.endIndent : _style.indent;
    final right = size.width - (rtl ? _style.indent : _style.endIndent);
    if (right <= left) return;
    final paint = Paint()..color = _style.color;
    final y = offset.dy + (size.height - _style.thickness) / 2;
    if (_style.thickness == 0) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0;
      context.canvas.drawLine(
        Offset(offset.dx + left, y),
        Offset(offset.dx + right, y),
        paint,
      );
      return;
    }
    context.canvas.drawRect(
      Rect.fromLTWH(offset.dx + left, y, right - left, _style.thickness),
      paint,
    );
  }
}
