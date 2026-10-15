import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:jackdaw_native/jackdaw_native.dart';
import 'package:test/test.dart';

import 'model_server.dart';

final List<int> _bytes = List.generate(3 << 20, (i) => Random(i).nextInt(256));

/// A served model file, an empty download folder and a downloader.
final class DownloadFixture {
  new _(this.server, this.folder, this.model);

  /// Starts the server and makes the folder.
  static Future<DownloadFixture> start() async {
    final server = await ModelServer.start(_bytes);
    return DownloadFixture._(
      server,
      Directory.systemTemp.createTempSync('jackdaw_download'),
      ModelFile(
        name: 'model.gguf',
        url: server.url.toString(),
        bytes: _bytes.length,
        sha256: '${sha256.convert(_bytes)}',
      ),
    );
  }

  /// The server of the file.
  final ModelServer server;

  /// The download folder.
  final Directory folder;

  /// The served file as a model.
  final ModelFile model;

  /// A downloader for [folder] that retries at once.
  ModelDownloader downloader() =>
      ModelDownloader(folder, retryDelay: Duration.zero);

  /// Leaves the first [length] bytes as an interrupted download.
  void leavePart(int length) =>
      File('${folder.path}/model.gguf.part')
          .writeAsBytesSync(_bytes.sublist(0, length));

  /// Expects [file] to be the whole model with no part file left.
  void expectDone(File file) {
    expect(file.readAsBytesSync(), _bytes);
    expect(File('${file.path}.part').existsSync(), isFalse);
  }

  /// Stops the server and deletes the folder.
  Future<void> close() async {
    await server.close();
    folder.deleteSync(recursive: true);
  }
}
