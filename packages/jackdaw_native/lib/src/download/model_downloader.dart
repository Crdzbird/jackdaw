import 'dart:io';

import 'package:jackdaw_native/src/download/model_download_exception.dart';
import 'package:jackdaw_native/src/download/model_download_progress.dart';
import 'package:jackdaw_native/src/download/model_file.dart';
import 'package:jackdaw_native/src/download/model_hash.dart';
import 'package:jackdaw_native/src/download/model_receive.dart';

HttpClient _client() =>
    HttpClient()..findProxy = HttpClient.findProxyFromEnvironment;

/// Keeps model files in a folder, downloading each one the first time it
/// is asked for.
///
/// Bytes go to a `.part` file first. An interrupted download resumes from
/// where it stopped, now or on a later run, and a dropped connection is
/// retried. The finished file is only used once its size and SHA-256
/// match; a marker file then records the check, so later runs skip it.
final class ModelDownloader {
  /// Creates a downloader for [directory]. [client] makes the HTTP client,
  /// such as one with a proxy; see [retries] and [retryDelay].
  factory(
    Directory directory, {
    HttpClient Function() client,
    int retries,
    Duration retryDelay,
  }) = ModelDownloader._;

  new _(
    this.directory, {
    HttpClient Function() client = _client,
    this.retries = 3,
    this.retryDelay = const Duration(seconds: 2),
  }) : _newClient = client;

  /// Where the models are kept.
  final Directory directory;

  /// How many times a dropped connection is retried.
  final int retries;

  /// The wait before a retry.
  final Duration retryDelay;

  final HttpClient Function() _newClient;
  final Map<String, Future<File>> _running = {};

  /// [model] in [directory], downloaded and checked first when needed.
  /// Calls for a file that is already downloading share that download.
  ///
  /// Throws [ModelDownloadException] when the server refuses the file or
  /// the bytes do not match; mismatching bytes are deleted.
  Future<File> fetch(
    ModelFile model, {
    void Function(ModelDownloadProgress progress)? onProgress,
  }) async {
    final running = _running[model.name] ??= _fetch(model, onProgress);
    try {
      return await running;
    } finally {
      _running.remove(model.name)?.ignore();
    }
  }

  Future<File> _fetch(
    ModelFile model,
    void Function(ModelDownloadProgress progress)? onProgress,
  ) async {
    final file = File('${directory.path}/${model.name}');
    if (modelChecked(file, model)) return file;
    await directory.create(recursive: true);
    final part = File('${file.path}.part');
    if (file.existsSync()) file.renameSync(part.path);
    for (var attempt = 0; ; attempt++) {
      final client = _newClient();
      try {
        await modelReceive(client, model, part, onProgress);
        break;
      } on IOException {
        if (attempt >= retries) rethrow;
      } finally {
        client.close(force: true);
      }
      await Future<void>.delayed(retryDelay);
    }
    final total = model.bytes;
    onProgress?.call(ModelDownloadProgress(total, total, checking: true));
    final hash = await modelHash(part.path);
    if (hash != model.sha256) {
      part.deleteSync();
      throw ModelDownloadException(
        '${model.name} has the SHA-256 $hash, not ${model.sha256}',
        url: Uri.parse(model.url),
      );
    }
    part.renameSync(file.path);
    File('${file.path}.sha256').writeAsStringSync(model.sha256);
    return file;
  }
}
