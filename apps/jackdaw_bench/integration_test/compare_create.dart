import 'dart:developer';

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'compare_side.dart';
import 'cpu_warm.dart';
import 'frame_summary.dart';
import 'frame_window.dart';
import 'ui_frame_surface.dart';

/// Draws a screen of [count] components with [side] alone on screen and
/// returns how long it took, from the messages to the last component, and
/// the frames of the second after.
Future<Map<String, Object>> measureCreate(
  WidgetTester tester,
  CompareSide side,
  int count,
) async {
  await tester.pumpWidget(compareScreen(side.view()));
  final create = side.prepare(uiFrameSurface(count));
  final frames = <FrameTiming>[];
  void collect(List<FrameTiming> timings) => frames.addAll(timings);
  SchedulerBinding.instance.addTimingsCallback(collect);
  final rate = tester.view.display.refreshRate;
  await Future<void>.delayed(const Duration(seconds: 1));
  warmCpu();
  final start = Timeline.now;
  final watch = Stopwatch()..start();
  side.apply(create);
  final applied = watch.elapsedMicroseconds;
  await SchedulerBinding.instance.endOfFrame;
  final shown = watch.elapsedMicroseconds;
  final last = [
    for (final t in ['Value 35', 'Field 36', 'Box 37']) find.text(t),
  ];
  for (var i = 0; i < 60 && last.any((f) => f.evaluate().isEmpty); i++) {
    await SchedulerBinding.instance.endOfFrame;
  }
  final complete = watch.elapsedMicroseconds;
  await Future<void>.delayed(const Duration(milliseconds: 500));
  expect(last, everyElement(findsOneWidget), reason: side.name);
  final end = Timeline.now;
  await Future<void>.delayed(const Duration(milliseconds: 500));
  SchedulerBinding.instance.removeTimingsCallback(collect);
  final created = framesWithin(frames, start, end);
  return {
    'to_frame_ms': shown / 1000,
    'complete_ms': complete / 1000,
    'create_build_sum_ms':
        created.fold(0, (sum, f) => sum + f.buildDuration.inMicroseconds) /
        1000,
    'apply_ms': applied / 1000,
    for (final MapEntry(:key, :value) in frameSummary(created, rate).entries)
      if (key != 'slow_frames') 'create_$key': value,
  };
}
