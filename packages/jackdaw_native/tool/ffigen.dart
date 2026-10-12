import 'dart:io';

import 'package:ffigen/ffigen.dart';

bool _ours(String name) => name.toLowerCase().startsWith('jackdaw');

Future<void> main() async {
  final packageRoot = Platform.script.resolve('../');
  final generator = FfiGenerator(
    output: Output(
      dart: DartOutput(
        path: packageRoot.resolve('lib/src/ffi/jackdaw_bindings.g.dart'),
      ),
    ),
    input: Input(
      entryPoints: [packageRoot.resolve('../../native/include/jackdaw.h')],
    ),
    visitors: [
      Visitor(
        func: (node) => node.isIncluded = _ours(node.name),
        struct: (node) => node.isIncluded = _ours(node.name),
        enumClass: (node) => node.isIncluded = _ours(node.name),
        macroConstant: (node) => node.isIncluded = _ours(node.name),
      ),
    ],
  );
  await generator.generate();
}
