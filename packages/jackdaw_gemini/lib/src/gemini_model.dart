import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_gemini/src/gemini_request_encoder.dart';
import 'package:jackdaw_gemini/src/gemini_stream_decoder.dart';

/// A [LanguageModel] backed by the Gemini API (`generateContent`).
///
/// Streams text, function calls and thinking. Thought signatures are kept
/// and sent back unchanged, which Gemini requires for function calling with
/// thinking models. Cancelling the stream aborts the request.
final class GeminiModel implements LanguageModel {
  /// Creates a model that calls [model], such as `gemini-3.8-flash`.
  const factory({
    required String model,
    required Secret apiKey,
    Uri? baseUrl,
    http.Client? client,
    Map<String, String> headers,
  }) = GeminiModel._;

  const new _({
    required this.model,
    required this._apiKey,
    this.baseUrl,
    this._client,
    this.headers = const {},
  });

  /// Model name sent to the API.
  final String model;

  /// API root; defaults to
  /// `https://generativelanguage.googleapis.com/v1beta/`.
  final Uri? baseUrl;

  /// Extra headers sent with every request.
  final Map<String, String> headers;

  final Secret _apiKey;
  final http.Client? _client;

  @override
  String get id => 'gemini/$model';

  @override
  Stream<ModelEvent> generate(ModelRequest request) {
    final decoder = GeminiStreamDecoder();
    final root =
        baseUrl ??
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/');
    final base = root.path.endsWith('/')
        ? root
        : root.replace(path: '${root.path}/');
    final url = base
        .resolve('models/$model:streamGenerateContent')
        .replace(queryParameters: const {'alt': 'sse'});
    final body = HttpTransport(provider: 'gemini', client: _client).postJson(
      url,
      headers: {...headers, 'x-goog-api-key': _apiKey.reveal()},
      body: encodeGenerateRequest(request),
    );
    return body
        .transform(const SseDecoder())
        .expand((event) => decoder.accept(jsonDecode(event.data)))
        .transform(appendOnDone(decoder.finish));
  }
}
