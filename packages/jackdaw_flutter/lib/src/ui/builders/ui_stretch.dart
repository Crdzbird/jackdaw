import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

part 'ui_stretch_render.dart';

/// [child] as wide as the space it is given when that width is bounded,
/// and as wide as it needs when it is not. In a column it stretches like
/// [CrossAxisAlignment.stretch] without ever asking for infinite width,
/// decided during layout, so nothing is built inside a LayoutBuilder.
final class UiStretch extends SingleChildRenderObjectWidget {
  /// Stretches [child] across.
  const factory({required Widget child, Key? key}) = UiStretch._;

  const new _({required super.child, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderUiStretch();
}
