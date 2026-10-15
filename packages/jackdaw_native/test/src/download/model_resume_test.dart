import 'dart:io';

import 'package:jackdaw_native/jackdaw_native.dart';
import 'package:test/test.dart';

import 'download_fixture.dart';

void main() {
  late DownloadFixture f;

  setUp(() async => f = await DownloadFixture.start());
  tearDown(() => f.close());

  test('an interrupted download resumes from its part file', () async {
    f.leavePart(1000);
    f.expectDone(await f.downloader().fetch(f.model));
    expect(f.server.ranges, ['bytes=1000-']);
  });

  test('a server without ranges makes it start over', () async {
    f
      ..leavePart(1000)
      ..server.ignoreRange = true;
    f.expectDone(await f.downloader().fetch(f.model));
  });

  test('a dropped connection is retried from where it stopped', () async {
    f.server.cutAt = 1 << 20;
    f.expectDone(await f.downloader().fetch(f.model));
    expect(f.server.ranges, hasLength(2));
    expect(f.server.ranges.last, startsWith('bytes='));
  });

  test('a redirect keeps the range', () async {
    f
      ..leavePart(10)
      ..server.redirect = true;
    f.expectDone(await f.downloader().fetch(f.model));
    expect(f.server.ranges, ['bytes=10-']);
  });

  test('a refused download fails after its retries', () async {
    f.server.status = HttpStatus.notFound;
    await expectLater(
      f.downloader().fetch(f.model),
      throwsA(isA<ModelDownloadException>()),
    );
    expect(f.server.ranges, hasLength(4));
  });
}
