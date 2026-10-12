import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:jackdaw_native/src/hook/cmake_build.dart';
import 'package:jackdaw_native/src/hook/native_target.dart';
import 'package:test/test.dart';

import 'code_config_fixture.dart';

void main() {
  test('reports CMake failures with their output', () async {
    final temp = Directory.systemTemp.createTempSync('jackdaw_cmake');
    addTearDown(() => temp.deleteSync(recursive: true));
    final build = CMakeBuild(
      source: temp.uri.resolve('missing/'),
      buildDirectory: temp.uri.resolve('build/'),
      target: NativeTarget(codeConfig(OS.linux, Architecture.x64)),
      ninja: 'jackdaw-no-such-tool',
    );
    expect(build.extraArguments, isEmpty);
    await expectLater(build.run(), throwsA(isA<ProcessException>()));
  });

  test('builds the jackdaw target and returns the library', () async {
    final temp = Directory.systemTemp.createTempSync('jackdaw_cmake_ok');
    addTearDown(() => temp.deleteSync(recursive: true));
    File.fromUri(temp.uri.resolve('src/lib.c'))
      ..createSync(recursive: true)
      ..writeAsStringSync('int jackdaw_probe(void) { return 1; }\n');
    File.fromUri(temp.uri.resolve('src/CMakeLists.txt')).writeAsStringSync(
      'cmake_minimum_required(VERSION 3.24)\n'
      'project(probe C)\n'
      'add_library(jackdaw SHARED lib.c)\n',
    );
    final os = Platform.isMacOS ? OS.macOS : OS.linux;
    final arch = Platform.version.contains('arm64')
        ? Architecture.arm64
        : Architecture.x64;
    final library = await CMakeBuild(
      source: temp.uri.resolve('src/'),
      buildDirectory: temp.uri.resolve('build/'),
      target: NativeTarget(codeConfig(os, arch)),
    ).run();
    expect(File.fromUri(library).existsSync(), isTrue);
  });
}
