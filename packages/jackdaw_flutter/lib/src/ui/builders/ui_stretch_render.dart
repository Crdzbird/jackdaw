part of 'ui_stretch.dart';

final class _RenderUiStretch extends RenderProxyBox {
  BoxConstraints _stretched(BoxConstraints constraints) =>
      constraints.hasBoundedWidth
      ? constraints.tighten(width: constraints.maxWidth)
      : constraints;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      child!.getDryLayout(_stretched(constraints));

  @override
  void performLayout() {
    child!.layout(_stretched(constraints), parentUsesSize: true);
    size = child!.size;
  }
}
