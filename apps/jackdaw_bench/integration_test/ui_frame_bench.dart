import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

import 'frame_summary.dart';
import 'ui_frame_surface.dart';

/// Claim C14: frame times while a surface of [count] components is
/// created and then changed [updates] times, one data write per frame,
/// against the same screen idle. A spinner keeps frames coming.
Future<Map<String, Object>> runUiFrameBench(
  WidgetTester tester, {
  int count = 40,
  int updates = 120,
}) async {
  final ui = UiSurfaceController(basicCatalog);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            const CircularProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                child: UiSurfaceView(controller: ui, surfaceId: 'bench'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  final frames = <FrameTiming>[];
  void collect(List<FrameTiming> timings) => frames.addAll(timings);
  SchedulerBinding.instance.addTimingsCallback(collect);
  final rate = tester.view.display.refreshRate;
  await Future<void>.delayed(const Duration(seconds: 3));
  final idle = [...frames];
  frames.clear();
  ui.applyAll([uiFrameSurface(count)]);
  await SchedulerBinding.instance.endOfFrame;
  for (var i = 0; i < updates; i++) {
    ui.write('bench', '/t${(i * 5) % count}', 'Update $i');
    await SchedulerBinding.instance.endOfFrame;
  }
  await Future<void>.delayed(const Duration(milliseconds: 1200));
  final busy = [...frames];
  SchedulerBinding.instance.removeTimingsCallback(collect);
  return {
    'refresh_hz': rate,
    'budget_ms': 1000 / rate,
    'components': count,
    'updates': updates,
    'idle': frameSummary(idle, rate),
    'updating': frameSummary(busy, rate),
  };
}
