import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jackdaw/src/http/read_provider_error.dart';

/// Posts JSON to a model provider and streams the response body.
///
/// Failed responses become a `ProviderException`. Cancelling the returned
/// stream aborts the request. Pass a `client` to reuse connections, add a
/// proxy or record traffic; otherwise a client is created per request.
final class HttpTransport {
  /// Creates a transport for [provider].
  const factory({required String provider, http.Client? client}) =
      HttpTransport._;

  const new _({required this.provider, this._client});

  /// Provider name used in errors, such as `anthropic`.
  final String provider;

  final http.Client? _client;

  /// Posts [body] as JSON to [url] with [headers] and streams the bytes.
  Stream<List<int>> postJson(
    Uri url, {
    required Map<String, String> headers,
    required Object? body,
  }) async* {
    final abort = Completer<void>();
    final client = _client ?? http.Client();
    var finished = false;
    try {
      final request =
          http.AbortableRequest('POST', url, abortTrigger: abort.future)
            ..headers.addAll({...headers, 'content-type': 'application/json'})
            ..body = jsonEncode(body);
      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode > 299) {
        throw await readProviderError(provider, response);
      }
      yield* response.stream;
      finished = true;
    } finally {
      if (!finished) abort.complete();
      if (_client == null) client.close();
    }
  }
}
