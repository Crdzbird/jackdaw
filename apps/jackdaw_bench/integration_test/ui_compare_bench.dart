import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bench_config.dart';
import 'compare_side.dart';
import 'frame_summary.dart';
import 'genui_side.dart';
import 'jackdaw_side.dart';
import 'ui_frame_surface.dart';

/// Claim C14 against Flutter's genui: the same surface of [count]
/// components, within jackdaw's 40 per message, drawn by jackdaw_flutter
/// and by genui, then changed [updates] times, one data write per frame.
/// The sides take turns: a warm-up round, then [rounds] reported ones.
Future<Map<String, Object>> runUiCompareBench(
  WidgetTester tester, {
  int count = 40,
  int updates = 120,
  int rounds = 5,
}) async {
  for (var round = 0; round <= rounds; round++) {
    for (final make in <CompareSide Function()>[
      JackdawSide.new,
      GenuiSide.new,
    ]) {
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
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            const CircularProgressIndicator(),
            Expanded(child: SingleChildScrollView(child: side.view())),
          ],
        ),
      ),
    ),
  );
  final create = side.prepare(uiFrameSurface(count));
  final changes = [
    for (var i = 0; i < updates; i++)
      side.prepare({
        'version': 'v1.0',
        'updateDataModel': {
          'surfaceId': 'bench',
          'path': '/t${(i * 5) % count}',
          'value': 'Update $i',
        },
      }),
  ];
  final frames = <FrameTiming>[];
  void collect(List<FrameTiming> timings) => frames.addAll(timings);
  SchedulerBinding.instance.addTimingsCallback(collect);
  final rate = tester.view.display.refreshRate;
  await Future<void>.delayed(const Duration(seconds: 1));
  frames.clear();
  final watch = Stopwatch()..start();
  side.apply(create);
  final applied = watch.elapsedMicroseconds;
  await SchedulerBinding.instance.endOfFrame;
  final shown = watch.elapsedMicroseconds;
  await Future<void>.delayed(const Duration(milliseconds: 500));
  expect(find.text('Value 0'), findsOneWidget, reason: side.name);
  final created = [...frames];
  frames.clear();
  final costs = <int>[];
  for (final change in changes) {
    final step = Stopwatch()..start();
    side.apply(change);
    costs.add(step.elapsedMicroseconds);
    await SchedulerBinding.instance.endOfFrame;
  }
  await Future<void>.delayed(const Duration(milliseconds: 1200));
  SchedulerBinding.instance.removeTimingsCallback(collect);
  costs.sort();
  return {
    'to_frame_ms': shown / 1000,
    'apply_ms': applied / 1000,
    'update_apply_p50_ms': costs[costs.length ~/ 2] / 1000,
    for (final (phase, list) in [('create', created), ('update', frames)])
      for (final MapEntry(:key, :value) in frameSummary(list, rate).entries)
        if (key != 'slow_frames') '${phase}_$key': value,
  };
}
