import 'dart:developer';
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'compare_pair.dart';
import 'compare_side.dart';
import 'frame_summary.dart';
import 'heap_settle.dart';
import 'ui_frame_surface.dart';

/// Writes [updates] values to the screens [sides] already hold, both on
/// screen, the sides taking turns one frame each, so every write meets the
/// core at the clock the other side's writes keep it at. Each frame counts
/// for the side that wrote in it. The heap is settled first; see
/// [settleHeap]. Returns each side's numbers by name.
Future<Map<String, Map<String, Object>>> measureWrites(
  WidgetTester tester,
  List<CompareSide> sides,
  int count,
  int updates,
) async {
  await tester.pumpWidget(comparePair(sides[0].view(), sides[1].view()));
  final changes = [
    for (final side in sides)
      [for (var i = 0; i < updates; i++) side.prepare(uiFrameWrite(i, count))],
  ];
  final frames = <FrameTiming>[];
  void collect(List<FrameTiming> timings) => frames.addAll(timings);
  SchedulerBinding.instance.addTimingsCallback(collect);
  final rate = tester.view.display.refreshRate;
  await Future<void>.delayed(const Duration(milliseconds: 250));
  settleHeap();
  await Future<void>.delayed(const Duration(milliseconds: 250));
  final spans = [for (final _ in sides) <(int, int)>[]];
  final costs = [for (final _ in sides) <int>[]];
  for (var i = 0; i < updates; i++) {
    for (var s = 0; s < sides.length; s++) {
      final from = Timeline.now;
      final step = Stopwatch()..start();
      sides[s].apply(changes[s][i]);
      costs[s].add(step.elapsedMicroseconds);
      await SchedulerBinding.instance.endOfFrame;
      spans[s].add((from, Timeline.now));
    }
  }
  await Future<void>.delayed(const Duration(milliseconds: 1500));
  SchedulerBinding.instance.removeTimingsCallback(collect);
  bool inside(FrameTiming f, List<(int, int)> list) {
    final at = f.timestampInMicroseconds(FramePhase.buildStart);
    return list.any((span) => at >= span.$1 && at < span.$2);
  }

  return {
    for (var s = 0; s < sides.length; s++)
      sides[s].name: {
        'update_apply_p50_ms': (costs[s]..sort())[updates ~/ 2] / 1000,
        for (final MapEntry(:key, :value) in frameSummary([
          for (final f in frames)
            if (inside(f, spans[s])) f,
        ], rate).entries)
          if (key != 'slow_frames') 'update_$key': value,
      },
  };
}
