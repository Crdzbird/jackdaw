import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

/// Builds the code configuration a hook would see for [os] and [arch].
CodeConfig codeConfig(OS os, Architecture arch, {CCompilerConfig? compiler}) {
  final builder = BuildInputBuilder()
    ..setupShared(
      packageRoot: Uri.directory('/tmp/jackdaw_native/'),
      packageName: 'jackdaw_native',
      outputDirectoryShared: Uri.directory('/tmp/jackdaw_out/'),
      outputFile: Uri.file('/tmp/jackdaw_out/output.json'),
    )
    ..config.setupBuild(linkingEnabled: false)
    ..addExtension(
      CodeAssetExtension(
        targetArchitecture: arch,
        targetOS: os,
        linkModePreference: LinkModePreference.dynamic,
        cCompiler: compiler,
        android: os == OS.android ? AndroidCodeConfig(targetNdkApi: 24) : null,
        iOS: os == OS.iOS
            ? IOSCodeConfig(
                targetSdk: IOSSdk.iPhoneSimulator,
                targetVersion: 17,
              )
            : null,
        macOS: os == OS.macOS ? MacOSCodeConfig(targetVersion: 13) : null,
      ),
    );
  return builder.build().config.code;
}
