import 'package:flutter/widgets.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

import 'compare_side.dart';

/// jackdaw_flutter: messages go to a UiSurfaceController as they are.
final class JackdawSide implements CompareSide {
  final UiSurfaceController _ui = UiSurfaceController(basicCatalog);

  @override
  String get name => 'jackdaw_flutter';

  @override
  List<Map<String, Object?>> prepare(Map<String, Object?> message) => [message];

  @override
  void apply(List<Map<String, Object?>> messages) => _ui.applyAll(messages);

  @override
  Widget view() => UiSurfaceView(controller: _ui, surfaceId: 'bench');

  @override
  void dispose() => _ui.dispose();
}
