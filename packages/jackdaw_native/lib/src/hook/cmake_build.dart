import 'dart:io';

import 'package:jackdaw_native/src/hook/native_target.dart';

/// Configures and builds `libjackdaw` with CMake for one target.
final class CMakeBuild {
  /// Creates a build of [source] into [buildDirectory] for [target].
  const factory({
    required Uri source,
    required Uri buildDirectory,
    required NativeTarget target,
    List<String> extraArguments,
    String ninja,
  }) = CMakeBuild._;

  const new _({
    required this.source,
    required this.buildDirectory,
    required this.target,
    this.extraArguments = const [],
    this.ninja = 'ninja',
  });

  /// Directory holding the top-level `CMakeLists.txt`.
  final Uri source;

  /// Where CMake keeps its cache; reused for incremental builds.
  final Uri buildDirectory;

  /// The platform to build for.
  final NativeTarget target;

  /// Additional `-D` arguments.
  final List<String> extraArguments;

  /// Ninja executable; when missing CMake's default generator is used.
  final String ninja;

  /// Builds the library and returns its location.
  Future<Uri> run() async {
    final build = buildDirectory.toFilePath();
    final useNinja = await _has(ninja);
    await _exec('cmake', [
      '-S',
      source.toFilePath(),
      '-B',
      build,
      if (useNinja) ...['-G', 'Ninja'],
      '-DCMAKE_BUILD_TYPE=Release',
      '-DJACKDAW_STRIP=ON',
      ...target.cmakeArguments,
      ...extraArguments,
    ]);
    await _exec('cmake', ['--build', build, '--target', 'jackdaw', '-j']);
    return buildDirectory.resolve(target.fileName);
  }

  static Future<bool> _has(String tool) async {
    try {
      return (await Process.run(tool, ['--version'])).exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  static Future<void> _exec(String executable, List<String> arguments) async {
    final result = await Process.run(executable, arguments);
    if (result.exitCode != 0) {
      throw ProcessException(
        executable,
        arguments,
        '${result.stdout}\n${result.stderr}',
        result.exitCode,
      );
    }
  }
}
