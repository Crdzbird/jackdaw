import 'package:flutter/material.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

/// The screen the model built last, scrolling when it is tall.
class UiStudioScreen extends StatelessWidget {
  const new({required this.ui, super.key});

  /// The controller holding the screen, if one was built.
  final UiSurfaceController? ui;

  @override
  Widget build(BuildContext context) {
    final controller = ui;
    final surfaceId = controller?.surfaces.surfaces.keys.lastOrNull;
    return SingleChildScrollView(
      child: switch ((controller, surfaceId)) {
        (final controller?, final id?) => UiSurfaceView(
          controller: controller,
          surfaceId: id,
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
