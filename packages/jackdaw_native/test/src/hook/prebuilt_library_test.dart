import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:jackdaw_native/src/hook/native_target.dart';
import 'package:jackdaw_native/src/hook/prebuilt_library.dart';
import 'package:test/test.dart';

import 'code_config_fixture.dart';

const _bytes = 'libjackdaw';
const _hash =
    '7c20086fe93022123b8f0a9f4865c924e70c865a589735e2d579c3103320f501';

void main() {
  late HttpServer server;
  late Directory out;
  var requests = 0;
  final target = NativeTarget(codeConfig(OS.linux, Architecture.x64));

  setUp(() async {
    requests = 0;
    out = Directory.systemTemp.createTempSync('jackdaw_prebuilt');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
      ..listen((request) async {
        requests++;
        final found = request.uri.path == '/v1/linux-x64-libjackdaw.so';
        request.response.statusCode = found ? 200 : 404;
        if (found) request.response.write(_bytes);
        await request.response.close();
      });
  });

  tearDown(() async {
    await server.close(force: true);
    out.deleteSync(recursive: true);
  });

  PrebuiltLibrary library(String hash, {String tag = 'v1'}) => PrebuiltLibrary(
    hashes: {'linux-x64': hash},
    tag: tag,
    baseUrl: 'http://${server.address.host}:${server.port}',
  );

  test('downloads, verifies and then reuses the cached file', () async {
    final file = await library(_hash).fetch(target, out.uri);
    expect(File.fromUri(file).readAsStringSync(), _bytes);
    await library(_hash).fetch(target, out.uri);
    expect(requests, 1);
  });

  test('deletes files whose hash does not match', () async {
    await expectLater(
      library('0' * 64).fetch(target, out.uri),
      throwsStateError,
    );
    expect(
      File.fromUri(out.uri.resolve('libjackdaw.so')).existsSync(),
      isFalse,
    );
  });

  test('reports missing releases and missing targets', () async {
    final missing = NativeTarget(codeConfig(OS.linux, Architecture.arm64));
    await expectLater(
      library(_hash).fetch(missing, out.uri),
      throwsUnsupportedError,
    );
    final other = PrebuiltLibrary(
      hashes: const {'linux-x64': _hash},
      baseUrl: 'http://${server.address.host}:${server.port}/nope',
    );
    await expectLater(
      other.fetch(target, out.uri),
      throwsA(isA<HttpException>()),
    );
  });
}
