import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:jackdaw_native/src/hook/cmake_build.dart';
import 'package:jackdaw_native/src/hook/native_target.dart';
import 'package:jackdaw_native/src/hook/prebuilt_library.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    final target = NativeTarget(
      input.config.code,
      baselineCpu: input.userDefines['android_cpu'] == 'baseline',
    );
    final library = input.userDefines['build'] == 'source'
        ? await _fromSource(input, output, target)
        : await const PrebuiltLibrary().fetch(target, input.outputDirectory);
    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: 'src/ffi/jackdaw_bindings.g.dart',
        linkMode: DynamicLoadingBundled(),
        file: library,
      ),
    );
  });
}

Future<Uri> _fromSource(
  BuildInput input,
  BuildOutputBuilder output,
  NativeTarget target,
) async {
  final source = input.packageRoot.resolve('../../native/');
  final llama = input.userDefines.path('llama_cpp_source');
  final built = await CMakeBuild(
    source: source,
    buildDirectory: input.outputDirectoryShared.resolve('cmake-${target.key}/'),
    target: target,
    extraArguments: [
      if (llama != null)
        '-DFETCHCONTENT_SOURCE_DIR_LLAMA_CPP=${llama.toFilePath()}',
    ],
  ).run();
  output.dependencies.addAll([
    for (final entity in Directory.fromUri(source).listSync(recursive: true))
      if (entity is File && !entity.path.contains('/build/')) entity.uri,
  ]);
  final copy = File.fromUri(input.outputDirectory.resolve(target.fileName));
  await File.fromUri(built).copy(copy.path);
  return copy.uri;
}
