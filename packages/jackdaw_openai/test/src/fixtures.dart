import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Encodes [chunks] as an OpenAI SSE body ending with `[DONE]`.
Stream<List<int>> sseBody(List<Object?> chunks) => Stream.fromIterable([
  for (final chunk in chunks) utf8.encode('data: ${jsonEncode(chunk)}\n\n'),
  utf8.encode('data: [DONE]\n\n'),
]);

/// A client that answers every request with [status] and [body].
MockClient replying(
  Stream<List<int>> body, {
  int status = 200,
  Map<String, String> headers = const {},
  void Function(http.BaseRequest request)? onRequest,
}) => MockClient.streaming((request, _) async {
  onRequest?.call(request);
  return http.StreamedResponse(body, status, headers: headers);
});

/// A chunk carrying a text delta.
Map<String, Object?> textChunk(String text) => {
  'choices': [
    {
      'delta': {'content': text},
    },
  ],
};
