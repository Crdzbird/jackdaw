import 'package:code_assets/code_assets.dart';
import 'package:jackdaw_native/src/hook/native_target.dart';
import 'package:test/test.dart';

import 'code_config_fixture.dart';

void main() {
  final ndkClang = Uri.file(
    '/ndk/28/toolchains/llvm/prebuilt/darwin-x86_64/bin/clang',
  );
  final compiler = CCompilerConfig(
    archiver: ndkClang,
    compiler: ndkClang,
    linker: ndkClang,
  );

  test('android arm64 uses the NDK toolchain and dotprod kernels', () {
    final target = NativeTarget(
      codeConfig(OS.android, Architecture.arm64, compiler: compiler),
    );
    expect(target.key, 'android-arm64');
    expect(target.fileName, 'libjackdaw.so');
    expect(target.cmakeArguments, [
      '-DCMAKE_TOOLCHAIN_FILE=/ndk/28/build/cmake/android.toolchain.cmake',
      '-DANDROID_ABI=arm64-v8a',
      '-DANDROID_PLATFORM=android-24',
      '-DANDROID_STL=c++_static',
      '-DGGML_CPU_ARM_ARCH=armv8.2-a+dotprod+fp16',
    ]);
  });

  test('32-bit android drops the fp16-only llamafile kernels', () {
    final target = NativeTarget(
      codeConfig(OS.android, Architecture.arm, compiler: compiler),
    );
    expect(target.cmakeArguments, contains('-DANDROID_ABI=armeabi-v7a'));
    expect(target.cmakeArguments.last, '-DGGML_LLAMAFILE=OFF');
  });

  test('android without a compiler fails clearly', () {
    final target = NativeTarget(codeConfig(OS.android, Architecture.x64));
    expect(() => target.cmakeArguments, throwsStateError);
  });

  test('apple targets set architecture and deployment target', () {
    final mac = NativeTarget(codeConfig(OS.macOS, Architecture.x64));
    expect(mac.key, 'macos-x64');
    expect(mac.fileName, 'libjackdaw.dylib');
    expect(mac.cmakeArguments, [
      '-DCMAKE_OSX_ARCHITECTURES=x86_64',
      '-DCMAKE_OSX_DEPLOYMENT_TARGET=13',
    ]);
    final ios = NativeTarget(codeConfig(OS.iOS, Architecture.arm64));
    expect(ios.key, 'ios-iphonesimulator-arm64');
    expect(ios.cmakeArguments, contains('-DCMAKE_SYSTEM_NAME=iOS'));
    expect(ios.cmakeArguments.last, '-DGGML_METAL=OFF');
  });

  test('desktop hosts need no extra arguments', () {
    final linux = NativeTarget(codeConfig(OS.linux, Architecture.x64));
    expect(linux.cmakeArguments, isEmpty);
    expect(linux.fileName, 'libjackdaw.so');
  });
}
