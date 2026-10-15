import 'dart:io';

/// A local HTTP server for one model file, with switches for the ways a
/// real server or network misbehaves.
final class ModelServer {
  new _(this._server, this.bytes);

  /// Serves [bytes] on a free loopback port.
  static Future<ModelServer> start(List<int> bytes) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final model = ModelServer._(server, bytes);
    server.listen(model._handle);
    return model;
  }

  final HttpServer _server;

  /// The file served.
  final List<int> bytes;

  /// The Range header of every request for the file, or null.
  final List<String?> ranges = [];

  /// Answer every request with the whole file.
  bool ignoreRange = false;

  /// Send the first response only up to this byte, then drop the socket.
  int? cutAt;

  /// Send a redirect to another path first.
  bool redirect = false;

  /// The status to answer with instead of the file.
  int? status;

  /// Where the file is.
  Uri get url => Uri.parse('http://127.0.0.1:${_server.port}/model.gguf');

  /// Stops the server.
  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    if (redirect && request.uri.path == '/model.gguf') {
      response
        ..statusCode = HttpStatus.found
        ..headers.set(HttpHeaders.locationHeader, '/cdn/model.gguf');
      await response.close();
      return;
    }
    final range = request.headers.value(HttpHeaders.rangeHeader);
    ranges.add(range);
    if (status case final code?) {
      response.statusCode = code;
      await response.close();
      return;
    }
    final asked = int.tryParse(
      RegExp(r'bytes=(\d+)-').firstMatch(range ?? '')?.group(1) ?? '',
    );
    final start = ignoreRange ? 0 : asked ?? 0;
    if (start > 0) {
      response
        ..statusCode = HttpStatus.partialContent
        ..headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $start-${bytes.length - 1}/${bytes.length}',
        );
    }
    response.contentLength = bytes.length - start;
    final cut = cutAt;
    if (cut == null || cut <= start) {
      response.add(bytes.sublist(start));
      await response.close();
      return;
    }
    cutAt = null;
    final socket = await response.detachSocket()
      ..add(bytes.sublist(start, cut));
    await socket.flush();
    socket.destroy();
  }
}
