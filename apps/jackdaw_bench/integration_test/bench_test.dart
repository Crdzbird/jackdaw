import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jackdaw_bench/src/cancel_bench.dart';
import 'package:jackdaw_bench/src/memory_bench.dart';
import 'package:jackdaw_bench/src/prefix_bench.dart';
import 'package:jackdaw_bench/src/structured_bench.dart';
import 'package:jackdaw_bench/src/structured_cases.dart';
import 'package:jackdaw_bench/src/throughput_bench.dart';
import 'package:jackdaw_bench/src/tool_bench.dart';
import 'package:jackdaw_bench/src/vector_bench.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

import 'chat_screen.dart';
import 'frame_bench.dart';

const _path = String.fromEnvironment('JACKDAW_MODEL');
const _only = String.fromEnvironment('BENCH');
const _semantics = bool.fromEnvironment('SEMANTICS');

bool _wanted(String name) => _only.isEmpty || _only.split(',').contains(name);

void _report(String name, Map<String, Object> data) =>
    debugPrint('BENCH ${jsonEncode({'name': name, ...data})}');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'benchmarks',
    (tester) async {
      if (_wanted('vectors')) {
        final directory = File(_path).parent.path;
        for (final clustered in [true, false]) {
          _report(
            'vectors',
            await runVectorBench(directory, clustered: clustered),
          );
        }
        if (_only == 'vectors') return;
      }
      if (_only == 'frametrace') {
        binding.framePolicy =
            LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
        final model = await LocalModel.open(_path);
        final chat = await pumpChatScreen(tester, model);
        await Future<void>.delayed(const Duration(seconds: 1));
        await binding.traceAction(() => chat.send(framePrompt));
        await chat.dispose();
        model.close();
        return;
      }
      if (_only == 'frames' || _only == 'framesweep') {
        binding.framePolicy =
            LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
        for (final threads in _only == 'frames' ? [0] : [4, 3, 2]) {
          final model = await LocalModel.open(
            _path,
            options: LocalModelOptions(
              session: NativeSessionOptions(threads: threads),
            ),
          );
          final result = await runFrameBench(tester, model);
          _report('frames', {'threads': threads, ...result});
          model.close();
        }
        return;
      }
      final watch = Stopwatch()..start();
      final model = await LocalModel.open(_path);
      _report('load', {'ms': watch.elapsedMilliseconds});
      if (_wanted('throughput')) {
        _report('throughput', await runThroughputBench(model));
      }
      if (_wanted('cancel')) _report('cancel', await runCancelBench(model));
      if (_wanted('tools')) _report('tools', await runToolBench(model));
      if (_wanted('prefix')) _report('prefix', await runPrefixBench(model));
      if (_wanted('structured')) {
        _report(
          'structured',
          await runStructuredBench(model, structuredCases()),
        );
      }
      model.close();
      if (_wanted('memory')) _report('memory', await runMemoryBench(_path));
    },
    timeout: const Timeout(Duration(minutes: 90)),
    semanticsEnabled: _semantics,
  );
}
