import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jackdaw_bench/src/cancel_bench.dart';
import 'package:jackdaw_bench/src/memory_bench.dart';
import 'package:jackdaw_bench/src/prefix_bench.dart';
import 'package:jackdaw_bench/src/structured_bench.dart';
import 'package:jackdaw_bench/src/structured_cases.dart';
import 'package:jackdaw_bench/src/throughput_bench.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

const _path = String.fromEnvironment('JACKDAW_MODEL');
const _only = String.fromEnvironment('BENCH');

bool _wanted(String name) => _only.isEmpty || _only.split(',').contains(name);

void _report(String name, Map<String, Object> data) =>
    debugPrint('BENCH ${jsonEncode({'name': name, ...data})}');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('phase 2 benchmarks', (tester) async {
    final watch = Stopwatch()..start();
    final model = await LocalModel.open(_path);
    _report('load', {'ms': watch.elapsedMilliseconds});
    if (_wanted('throughput')) {
      _report('throughput', await runThroughputBench(model));
    }
    if (_wanted('cancel')) _report('cancel', await runCancelBench(model));
    if (_wanted('prefix')) _report('prefix', await runPrefixBench(model));
    if (_wanted('structured')) {
      _report('structured', await runStructuredBench(model, structuredCases()));
    }
    model.close();
    if (_wanted('memory')) _report('memory', await runMemoryBench(_path));
  }, timeout: const Timeout(Duration(minutes: 90)));
}
