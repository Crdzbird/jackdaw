import 'dart:io';

import 'package:jackdaw_native/src/download/model_download_exception.dart';
import 'package:jackdaw_native/src/download/model_download_progress.dart';
import 'package:jackdaw_native/src/download/model_file.dart';
import 'package:jackdaw_native/src/download/model_get.dart';

const int _step = 1 << 20;

/// Downloads [model] into [part] with [client], continuing after the
/// bytes [part] already holds when the server allows it and starting
/// over when it does not. Reports [onProgress] about once per megabyte.
Future<void> modelReceive(
  HttpClient client,
  ModelFile model,
  File part,
  void Function(ModelDownloadProgress progress)? onProgress,
) async {
  final url = Uri.parse(model.url);
  var offset = part.existsSync() ? part.lengthSync() : 0;
  if (offset > model.bytes) {
    part.deleteSync();
    offset = 0;
  }
  if (offset == model.bytes) return;
  final response = await modelGet(client, url, offset);
  final range = response.headers.value(HttpHeaders.contentRangeHeader) ?? '';
  final resumed =
      response.statusCode == HttpStatus.partialContent &&
      range.startsWith('bytes $offset-');
  if (!resumed && response.statusCode != HttpStatus.ok) {
    await response.drain<void>();
    throw ModelDownloadException('HTTP ${response.statusCode}', url: url);
  }
  var received = resumed ? offset : 0;
  var reported = received;
  final sink = part.openWrite(
    mode: resumed ? FileMode.writeOnlyAppend : FileMode.writeOnly,
  );
  try {
    await for (final chunk in response) {
      sink.add(chunk);
      received += chunk.length;
      if (received - reported < _step) continue;
      reported = received;
      onProgress?.call(ModelDownloadProgress(received, model.bytes));
    }
  } finally {
    await sink.close();
  }
  if (received != model.bytes) {
    throw ModelDownloadException(
      'Received $received of ${model.bytes} bytes of ${model.name}',
      url: url,
    );
  }
}
