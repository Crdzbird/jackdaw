import 'dart:io';

import 'package:jackdaw_cli/jackdaw_cli.dart';

Future<void> main(List<String> args) async {
  exitCode = await runCli(args, stdout);
}
