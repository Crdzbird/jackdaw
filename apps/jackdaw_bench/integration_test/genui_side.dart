import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:flutter/widgets.dart';
import 'package:genui/genui.dart' as genui;
import 'package:jackdaw/jackdaw.dart';

import 'compare_side.dart';

/// Flutter's genui: messages are lowered to A2UI v0.9 ahead of time and
/// handed to its SurfaceController, as jackdaw's genui target does.
final class GenuiSide implements CompareSide {
  final genui.SurfaceController _controller = genui.SurfaceController(
    catalogs: [genui.BasicCatalogItems.asCatalog()],
  );

  @override
  String get name => 'genui';

  @override
  List<Map<String, Object?>> prepare(Map<String, Object?> message) =>
      uiLowerToV09([message], basicCatalog);

  @override
  void apply(List<Map<String, Object?>> messages) {
    for (final message in messages) {
      _controller.handleMessage(a2ui.A2uiMessage.fromJson(message));
    }
  }

  @override
  Widget view() =>
      genui.Surface(surfaceContext: _controller.contextFor('bench'));

  @override
  void dispose() => _controller.dispose();
}
