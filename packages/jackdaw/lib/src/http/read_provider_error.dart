import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jackdaw/src/error/provider_exception.dart';
import 'package:jackdaw/src/error/retry_after.dart';

const int _maxErrorBytes = 64 * 1024;

/// Reads a failed [response] from [provider] into a [ProviderException].
///
/// At most 64 KiB of the body are kept, so a hostile server cannot exhaust
/// memory through an error page. The message is taken from the common
/// `{"error": {"message": ...}}` and `{"error": "..."}` shapes.
Future<ProviderException> readProviderError(
  String provider,
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
    provider: provider,
    message: _message(body) ?? 'HTTP ${response.statusCode}',
    statusCode: response.statusCode,
    retryAfter: parseRetryAfter(response.headers['retry-after']),
  );
}

String? _message(String body) => switch (_tryDecode(body)) {
  {'error': {'message': final String message}} => message,
  {'error': final String message} => message,
  _ => null,
};

Object? _tryDecode(String body) {
  try {
    return jsonDecode(body);
  } on FormatException {
    return null;
  }
}
