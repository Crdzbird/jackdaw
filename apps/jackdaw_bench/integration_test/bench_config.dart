import 'dart:convert';

import 'package:flutter/foundation.dart';

/// The GGUF file the benchmarks load.
const benchModel = String.fromEnvironment('JACKDAW_MODEL');

/// The benchmarks to run, comma separated, or all when empty.
const benchOnly = String.fromEnvironment('BENCH');

/// Whether the semantics tree is on while benchmarking.
const benchSemantics = bool.fromEnvironment('SEMANTICS');

/// The modes that need every frame drawn live.
const benchLive = {
  'uiframes',
  'uicompare',
  'frametrace',
  'frames',
  'framesweep',
};

/// Whether the benchmark [name] runs.
bool benchWanted(String name) =>
    benchOnly.isEmpty || benchOnly.split(',').contains(name);

/// Prints the result [data] of the benchmark [name] for the runner.
void benchReport(String name, Map<String, Object> data) =>
    debugPrint('BENCH ${jsonEncode({'name': name, ...data})}');
