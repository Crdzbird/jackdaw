import 'dart:io';

import 'package:jackdaw_cli/jackdaw_cli.dart';

/// Runs the CLI in process, for example from a build script.
Future<void> main() async {
  exitCode = await runCli(['help'], stdout);
}
