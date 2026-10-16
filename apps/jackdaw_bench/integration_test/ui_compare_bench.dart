import 'dart:developer';
import 'dart:ui' show FramePhase;

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bench_config.dart';
import 'compare_side.dart';
import 'cpu_warm.dart';
import 'frame_summary.dart';
import 'genui_side.dart';
import 'jackdaw_side.dart';
import 'ui_frame_surface.dart';

/// Claim C14 against genui: the same [count] components drawn by both,
/// then written [updates] times, one write per frame. The sides take
/// turns in alternating order: a warm-up round, then [rounds] reported.
Future<Map<String, Object>> runUiCompareBench(
  WidgetTester tester, {
  int count = 40,
  int updates = 120,
  int rounds = 5,
}) async {
  for (var round = 0; round <= rounds; round++) {
    final sides = <CompareSide Function()>[JackdawSide.new, GenuiSide.new];
    for (final make in round.isEven ? sides : sides.reversed) {
      final side = make();
      final result = await _measure(tester, side, count, updates);
      if (round > 0) benchReport('uicompare', {'side': side.name, ...result});
      side.dispose();
    }
  }
  return {'components': count, 'updates': updates, 'rounds': rounds};
}

Future<Map<String, Object>> _measure(
  WidgetTester tester,
  CompareSide side,
  int count,
  int updates,
) async {
  await tester.pumpWidget(compareScreen(side.view()));
  final create = side.prepare(uiFrameSurface(count));
  final changes = [
    for (var i = 0; i < updates; i++) side.prepare(uiFrameWrite(i, count)),
  ];
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
  final middle = Timeline.now;
  final costs = <int>[];
  for (final change in changes) {
    final step = Stopwatch()..start();
    side.apply(change);
    costs.add(step.elapsedMicroseconds);
    await SchedulerBinding.instance.endOfFrame;
  }
  final end = Timeline.now;
  await Future<void>.delayed(const Duration(milliseconds: 1500));
  SchedulerBinding.instance.removeTimingsCallback(collect);
  costs.sort();
  List<FrameTiming> within(int from, int to) => [
    for (final f in frames)
      if (f.timestampInMicroseconds(FramePhase.buildStart) case final at
          when at >= from && at < to)
        f,
  ];
  final created = within(start, middle);
  return {
    'to_frame_ms': shown / 1000,
    'complete_ms': complete / 1000,
    'create_build_sum_ms':
        created.fold(0, (sum, f) => sum + f.buildDuration.inMicroseconds) /
        1000,
    'apply_ms': applied / 1000,
    'update_apply_p50_ms': costs[costs.length ~/ 2] / 1000,
    for (final (phase, list) in [
      ('create', created),
      ('update', within(middle, end)),
    ])
      for (final MapEntry(:key, :value) in frameSummary(list, rate).entries)
        if (key != 'slow_frames') '${phase}_$key': value,
  };
}
