import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';

import 'chat_screen.dart';
import 'frame_summary.dart';

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
    'idle': frameSummary(idleFrames, rate),
    'generating': frameSummary(busyFrames, rate),
  };
}
