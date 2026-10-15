import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jackdaw_bench/src/cancel_bench.dart';
import 'package:jackdaw_bench/src/memory_bench.dart';
import 'package:jackdaw_bench/src/prefix_bench.dart';
import 'package:jackdaw_bench/src/structured_bench.dart';
import 'package:jackdaw_bench/src/structured_cases.dart';
import 'package:jackdaw_bench/src/throughput_bench.dart';
import 'package:jackdaw_bench/src/tool_bench.dart';
import 'package:jackdaw_bench/src/ui_bench.dart';
import 'package:jackdaw_bench/src/ui_cases.dart';
import 'package:jackdaw_bench/src/vector_bench.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

import 'bench_config.dart';
import 'chat_screen.dart';
import 'frame_bench.dart';
import 'ui_frame_modes.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'benchmarks',
    (tester) async {
      if (benchWanted('vectors')) {
        final directory = File(benchModel).parent.path;
        for (final clustered in [true, false]) {
          benchReport(
            'vectors',
            await runVectorBench(directory, clustered: clustered),
          );
        }
        if (benchOnly == 'vectors') return;
      }
      if (benchLive.contains(benchOnly)) {
        binding.framePolicy =
            LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
      }
      if (uiFrameModes[benchOnly] case final run?) {
        return benchReport(benchOnly, await run(tester));
      }
      if (benchOnly == 'frametrace') {
        final model = await LocalModel.open(benchModel);
        final chat = await pumpChatScreen(tester, model);
        await Future<void>.delayed(const Duration(seconds: 1));
        await binding.traceAction(() => chat.send(framePrompt));
        await chat.dispose();
        model.close();
        return;
      }
      if (benchOnly == 'frames' || benchOnly == 'framesweep') {
        for (final threads in benchOnly == 'frames' ? [0] : [4, 3, 2]) {
          final model = await LocalModel.open(
            benchModel,
            options: LocalModelOptions(
              session: NativeSessionOptions(threads: threads),
            ),
          );
          final result = await runFrameBench(tester, model);
          benchReport('frames', {'threads': threads, ...result});
          model.close();
        }
        return;
      }
      final watch = Stopwatch()..start();
      final model = await LocalModel.open(benchModel);
      benchReport('load', {'ms': watch.elapsedMilliseconds});
      if (benchWanted('throughput')) {
        benchReport('throughput', await runThroughputBench(model));
      }
      if (benchWanted('cancel')) {
        benchReport('cancel', await runCancelBench(model));
      }
      if (benchWanted('tools')) benchReport('tools', await runToolBench(model));
      if (benchWanted('prefix')) {
        benchReport('prefix', await runPrefixBench(model));
      }
      if (benchWanted('structured')) {
        benchReport(
          'structured',
          await runStructuredBench(model, structuredCases()),
        );
      }
      if (benchWanted('ui')) {
        benchReport('ui', await runUiBench(model, uiCases()));
      }
      model.close();
      if (benchWanted('memory')) {
        benchReport('memory', await runMemoryBench(benchModel));
      }
    },
    timeout: const Timeout(Duration(minutes: 90)),
    semanticsEnabled: benchSemantics,
  );
}
