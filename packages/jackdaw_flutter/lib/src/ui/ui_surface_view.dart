import 'package:flutter/material.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/ui/builders/basic_ui_builders.dart';
import 'package:jackdaw_flutter/src/ui/ui_node.dart';
import 'package:jackdaw_flutter/src/ui/ui_surface_controller.dart';
import 'package:jackdaw_flutter/src/ui/ui_widget_builder.dart';

/// Draws the surface [surfaceId] of [controller] from its root, and
/// redraws it whenever the controller changes.
///
/// Components are built by [builders], the basic catalog's by default; a
/// component without a builder, a missing child or a cycle draws nothing.
final class UiSurfaceView extends StatelessWidget {
  /// Shows [surfaceId] of [controller].
  const factory({
    required UiSurfaceController controller,
    required String surfaceId,
    Map<String, UiWidgetBuilder>? builders,
    Key? key,
  }) = UiSurfaceView._;

  const new _({
    required this.controller,
    required this.surfaceId,
    this.builders,
    super.key,
  });

  /// The controller that holds the surface.
  final UiSurfaceController controller;

  /// The surface to draw.
  final String surfaceId;

  /// The builders of the components, by name.
  final Map<String, UiWidgetBuilder>? builders;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final surface = controller.surfaces.surfaces[surfaceId];
      final root = surface?.root;
      if (surface == null || root == null) return const SizedBox.shrink();
      return Material(
        type: MaterialType.transparency,
        child: UiNode(
          controller: controller,
          surface: surface,
          component: root,
          scope: UiScope(surface.data),
          builders: builders ?? basicUiBuilders,
        ).build(),
      );
    },
  );
}
