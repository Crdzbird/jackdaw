import 'dart:io' as io;

import 'package:dart_mcp/stdio.dart';

import '../src/support/bird_server.dart';

void main() {
  BirdServer(stdioChannel(input: io.stdin, output: io.stdout));
}
