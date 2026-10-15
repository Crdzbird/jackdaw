import 'package:jackdaw_native/jackdaw_native.dart';
import 'package:test/test.dart';

import 'download_fixture.dart';

void main() {
  late DownloadFixture f;

  setUp(() async => f = await DownloadFixture.start());
  tearDown(() => f.close());

  test('downloads, checks and reports progress', () async {
    final seen = <ModelDownloadProgress>[];
    f.expectDone(await f.downloader().fetch(f.model, onProgress: seen.add));
    final received = [for (final p in seen) p.received];
    expect(received, hasLength(greaterThan(1)));
    expect(received, orderedEquals([...received]..sort()));
    expect(seen.last.checking, isTrue);
    expect(seen.last.fraction, 1);
  });

  test('a checked file is used without a request', () async {
    await f.downloader().fetch(f.model);
    f.expectDone(await f.downloader().fetch(f.model));
    expect(f.server.ranges, hasLength(1));
  });

  test('bytes with the wrong hash are deleted', () async {
    final bad = ModelFile(
      name: f.model.name,
      url: f.model.url,
      bytes: f.model.bytes,
      sha256: '0' * 64,
    );
    await expectLater(
      f.downloader().fetch(bad),
      throwsA(isA<ModelDownloadException>()),
    );
    expect(f.folder.listSync(), isEmpty);
  });

  test('calls for the same file share one download', () async {
    final loader = f.downloader();
    final files = await Future.wait([
      loader.fetch(f.model),
      loader.fetch(f.model),
    ]);
    expect(files.first.path, files.last.path);
    expect(f.server.ranges, hasLength(1));
  });
}
