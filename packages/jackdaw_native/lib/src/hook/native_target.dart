import 'package:code_assets/code_assets.dart';

/// The platform a build hook is producing `libjackdaw` for.
final class NativeTarget {
  /// Describes the target selected by [config].
  ///
  /// With [baselineCpu], Android arm64 is built for plain ARMv8.0 so it also
  /// runs on phones without dot-product instructions, at lower speed.
  factory(CodeConfig config, {bool baselineCpu}) = NativeTarget._;

  new _(this.config, {this.baselineCpu = false});

  /// The hook's code configuration.
  final CodeConfig config;

  /// Whether Android arm64 targets ARMv8.0 instead of ARMv8.2 with dotprod.
  final bool baselineCpu;

  bool get _dotprod =>
      config.targetArchitecture == Architecture.arm64 && !baselineCpu;

  /// Stable name used for build directories and prebuilt downloads.
  String get key {
    final os = config.targetOS;
    final arch = config.targetArchitecture.name;
    if (os == OS.iOS) return 'ios-${config.iOS.targetSdk.type}-$arch';
    if (os == OS.android && baselineCpu && arch == 'arm64') {
      return 'android-arm64-baseline';
    }
    return '${os.name}-$arch';
  }

  /// File name of the shared library on this target.
  String get fileName => config.targetOS.dylibFileName('jackdaw');

  /// CMake arguments that select the target toolchain.
  List<String> get cmakeArguments {
    final os = config.targetOS;
    if (os == OS.android) return _android();
    if (os == OS.macOS) {
      return [
        '-DCMAKE_OSX_ARCHITECTURES=$_appleArch',
        '-DCMAKE_OSX_DEPLOYMENT_TARGET=${config.macOS.targetVersion}',
      ];
    }
    if (os == OS.iOS) {
      return [
        '-DCMAKE_SYSTEM_NAME=iOS',
        '-DCMAKE_OSX_ARCHITECTURES=$_appleArch',
        '-DCMAKE_OSX_SYSROOT=${config.iOS.targetSdk.type}',
        '-DCMAKE_OSX_DEPLOYMENT_TARGET=${config.iOS.targetVersion}',
        if (config.iOS.targetSdk == IOSSdk.iPhoneSimulator) '-DGGML_METAL=OFF',
      ];
    }
    return const [];
  }

  String get _appleArch =>
      config.targetArchitecture == Architecture.x64 ? 'x86_64' : 'arm64';

  List<String> _android() {
    final compiler = config.cCompiler?.compiler;
    if (compiler == null) {
      throw StateError('Android builds need the NDK compiler from Flutter.');
    }
    final ndk = compiler.resolve('../../../../../').toFilePath();
    return [
      '-DCMAKE_TOOLCHAIN_FILE=${ndk}build/cmake/android.toolchain.cmake',
      '-DANDROID_ABI=${_androidAbis[config.targetArchitecture.name]}',
      '-DANDROID_PLATFORM=android-${config.android.targetNdkApi}',
      '-DANDROID_STL=c++_static',
      if (_dotprod) ...[
        '-DGGML_CPU_ARM_ARCH=armv8.2-a+dotprod+fp16',
        '-DJACKDAW_CPU_REQUIREMENTS=dotprod',
      ],
      if (config.targetArchitecture == Architecture.arm) '-DGGML_LLAMAFILE=OFF',
    ];
  }

  static const Map<String, String> _androidAbis = {
    'arm64': 'arm64-v8a',
    'arm': 'armeabi-v7a',
    'x64': 'x86_64',
    'ia32': 'x86',
  };
}
