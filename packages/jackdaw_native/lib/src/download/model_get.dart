import 'dart:io';

import 'package:jackdaw_native/src/download/model_download_exception.dart';

/// Starts a GET of [url] from byte [offset] on [client], following up to
/// [redirects] redirects itself so that every hop keeps the Range header.
/// Compression is turned off, so offsets count bytes of the file.
Future<HttpClientResponse> modelGet(
  HttpClient client,
  Uri url,
  int offset, {
  int redirects = 5,
}) async {
  var target = url;
  for (var hop = 0; hop <= redirects; hop++) {
    final request = await client.getUrl(target);
    request
      ..followRedirects = false
      ..headers.removeAll(HttpHeaders.acceptEncodingHeader);
    if (offset > 0) {
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=$offset-');
    }
    final response = await request.close();
    final location = response.headers.value(HttpHeaders.locationHeader);
    if (!response.isRedirect || location == null) return response;
    await response.drain<void>();
    target = target.resolve(location);
  }
  throw ModelDownloadException('Too many redirects', url: url);
}
