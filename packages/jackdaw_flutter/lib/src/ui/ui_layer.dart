import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

part 'ui_layer_render.dart';

/// [child] on a layer of its own, so it repaints apart from the rest of
/// its surface. With [stretch] it is as wide as the space it is given when
/// that width is bounded, and as wide as it needs when it is not: in a
/// column it stretches like [CrossAxisAlignment.stretch] without ever
/// asking for infinite width, decided during layout. One render object
/// does both, so a component costs one more, not two.
final class UiLayer extends SingleChildRenderObjectWidget {
  /// Puts [child] on a layer, stretched across when [stretch] is set.
  const factory({required Widget child, bool stretch, Key? key}) = UiLayer._;

  const new _({required super.child, this.stretch = false, super.key});

  /// Whether [child] takes the full width when it is bounded.
  final bool stretch;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderUiLayer(stretch: stretch);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderUiLayer).update(stretch: stretch);
  }
}
