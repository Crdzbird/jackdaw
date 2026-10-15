part of 'ui_stretch.dart';

final class _RenderUiStretch extends RenderProxyBox {
  BoxConstraints _stretched(BoxConstraints constraints) =>
      constraints.hasBoundedWidth
      ? constraints.tighten(width: constraints.maxWidth)
      : constraints;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      child?.getDryLayout(_stretched(constraints)) ?? constraints.smallest;

  @override
  void performLayout() {
    final box = child;
    if (box == null) {
      size = constraints.smallest;
      return;
    }
    box.layout(_stretched(constraints), parentUsesSize: true);
    size = box.size;
  }
}
