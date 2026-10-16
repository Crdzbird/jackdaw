import 'package:flutter/material.dart';

part 'ui_rule_render.dart';

/// A horizontal [Divider] drawn by one render object instead of eight: the
/// same space, thickness, indents and color from the [DividerTheme] and
/// the Material defaults, painted as a line.
final class UiRule extends LeafRenderObjectWidget {
  /// A divider across the width it is given.
  const factory({Key? key}) = UiRule._;

  const new _({super.key});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderUiRule(_style(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderUiRule).restyle(_style(context));
  }

  static _RuleStyle _style(BuildContext context) {
    final theme = DividerTheme.of(context);
    final material3 = Theme.of(context).useMaterial3;
    final side = Divider.createBorderSide(context);
    return (
      space: theme.space ?? 16,
      thickness: theme.thickness ?? (material3 ? 1 : 0),
      indent: theme.indent ?? 0,
      endIndent: theme.endIndent ?? 0,
      color: side.color,
      direction: Directionality.of(context),
    );
  }
}
