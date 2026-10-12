import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jackdaw/jackdaw.dart';

const int _maxErrorBytes = 64 * 1024;

/// Reads a failed response into a [ProviderException].
///
/// At most 64 KiB of the body are kept, so a hostile server cannot exhaust
/// memory through an error page.
Future<ProviderException> readOpenAiError(
  http.StreamedResponse response,
) async {
  final bytes = await response.stream.fold<List<int>>(
    [],
    (kept, chunk) =>
        kept.length >= _maxErrorBytes ? kept : (kept..addAll(chunk)),
  );
  final body = utf8.decode(
    bytes.take(_maxErrorBytes).toList(),
    allowMalformed: true,
  );
  return ProviderException(
    provider: 'openai',
    message: _message(body, response.statusCode),
    statusCode: response.statusCode,
    retryAfter: parseRetryAfter(response.headers['retry-after']),
  );
}

String _message(String body, int statusCode) {
  if (_tryDecode(body) case {'error': {'message': final String message}}) {
    return message;
  }
  return 'HTTP $statusCode';
}

Object? _tryDecode(String body) {
  try {
    return jsonDecode(body);
  } on FormatException {
    return null;
  }
}
