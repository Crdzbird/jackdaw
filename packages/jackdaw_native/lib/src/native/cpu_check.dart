import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';

/// Explains why this CPU cannot run a library built for [requirements], or
/// returns `null` when it can.
///
/// [cpuInfo] is the text of `/proc/cpuinfo`. Only the dot-product
/// requirement of the default Android arm64 build is checked.
String? cpuProblem(String requirements, String cpuInfo) {
  if (!requirements.contains('dotprod')) return null;
  final features = cpuInfo
      .split('\n')
      .where((line) => line.startsWith('Features'))
      .join(' ');
  if (features.isEmpty || features.contains('asimddp')) return null;
  return 'This phone has no ARMv8.2 dot-product instructions, which this '
      'build of libjackdaw needs. Add the user define '
      '"jackdaw_native: android_cpu: baseline" to ship a build that runs on '
      'it.';
}

/// Throws an [UnsupportedError] instead of letting an unsupported CPU crash
/// on an illegal instruction. Checks only on Android.
///
/// The parameters exist for tests; by default the loaded library's
/// requirements are compared with `/proc/cpuinfo`.
void checkCpu({
  bool? android,
  String? requirements,
  String Function() readCpuInfo = _readCpuInfo,
}) {
  if (!(android ?? Platform.isAndroid)) return;
  final needs =
      requirements ?? jackdaw_cpu_requirements().cast<Utf8>().toDartString();
  final problem = cpuProblem(needs, readCpuInfo());
  if (problem != null) throw UnsupportedError(problem);
}

String _readCpuInfo() {
  try {
    return File('/proc/cpuinfo').readAsStringSync();
  } on FileSystemException {
    return '';
  }
}
