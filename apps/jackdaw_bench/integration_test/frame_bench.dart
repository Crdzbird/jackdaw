import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';

import 'chat_screen.dart';

/// Claim C6: frame times of a live chat while [model] generates, compared
/// with the same screen idle. A spinner keeps frames coming in both phases.
/// One short turn runs first, as in a chat already in use, so first-time
/// text shaping does not count as inference.
Future<Map<String, Object>> runFrameBench(
  WidgetTester tester,
  LanguageModel model, {
  Duration idle = const Duration(seconds: 5),
}) async {
  final chat = await pumpChatScreen(tester, model);
  await chat.send('In one sentence, what is a bird?');
  final frames = <FrameTiming>[];
  void collect(List<FrameTiming> timings) => frames.addAll(timings);
  SchedulerBinding.instance.addTimingsCallback(collect);
  final rate = tester.view.display.refreshRate;
  await Future<void>.delayed(const Duration(seconds: 1));
  frames.clear();
  await Future<void>.delayed(idle);
  await Future<void>.delayed(const Duration(milliseconds: 1200));
  final idleFrames = [...frames];
  frames.clear();
  final watch = Stopwatch()..start();
  await chat.send(framePrompt);
  final seconds = watch.elapsedMilliseconds / 1000;
  await Future<void>.delayed(const Duration(milliseconds: 1200));
  final busyFrames = [...frames];
  SchedulerBinding.instance.removeTimingsCallback(collect);
  final answer = chat.state.messages.value.last.text;
  await chat.dispose();
  return {
    'refresh_hz': rate,
    'budget_ms': 1000 / rate,
    'generation_s': seconds,
    'answer_chars': answer.length,
    'idle': _summary(idleFrames, rate),
    'generating': _summary(busyFrames, rate),
  };
}

Map<String, Object> _summary(List<FrameTiming> frames, double rate) {
  final budget = 1e6 / rate;
  List<int> sorted(Iterable<Duration> values) =>
      [for (final d in values) d.inMicroseconds]..sort();
  double at(List<int> values, double p) =>
      values.isEmpty ? 0 : values[((values.length - 1) * p).round()] / 1000;
  final build = sorted(frames.map((f) => f.buildDuration));
  final raster = sorted(frames.map((f) => f.rasterDuration));
  return {
    'frames': frames.length,
    'build_p50_ms': at(build, 0.5),
    'build_p99_ms': at(build, 0.99),
    'build_max_ms': at(build, 1),
    'raster_p99_ms': at(raster, 0.99),
    'build_over_budget': build.where((b) => b > budget).length,
    'total_over_budget': frames
        .where((f) => f.totalSpan.inMicroseconds > budget)
        .length,
    'slow_frames': _slow(frames, budget),
  };
}

List<String> _slow(List<FrameTiming> frames, double budget) {
  if (frames.isEmpty) return const [];
  int at(FrameTiming f) => f.timestampInMicroseconds(FramePhase.vsyncStart);
  final start = at(frames.first);
  final end = (at(frames.last) - start) ~/ 1000;
  String describe(FrameTiming f) =>
      '${f.buildDuration.inMicroseconds / 1000} ms at '
      '${(at(f) - start) ~/ 1000} of $end';
  return [
    for (final f in frames)
      if (f.buildDuration.inMicroseconds > budget) describe(f),
  ];
}
