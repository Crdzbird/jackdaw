part of 'ui_layer.dart';

final class _RenderUiLayer extends RenderProxyBox {
  new({required this._stretch});

  bool _stretch;

  void update({required bool stretch}) {
    if (stretch == _stretch) return;
    _stretch = stretch;
    markNeedsLayout();
  }

  @override
  bool get isRepaintBoundary => true;

  BoxConstraints _given(BoxConstraints constraints) =>
      _stretch && constraints.hasBoundedWidth
      ? constraints.tighten(width: constraints.maxWidth)
      : constraints;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      child!.getDryLayout(_given(constraints));

  @override
  void performLayout() {
    child!.layout(_given(constraints), parentUsesSize: true);
    size = child!.size;
  }
}
