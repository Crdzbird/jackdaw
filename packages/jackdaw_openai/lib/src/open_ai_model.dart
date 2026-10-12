import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_openai/src/open_ai_request_encoder.dart';
import 'package:jackdaw_openai/src/open_ai_stream_decoder.dart';

/// A [LanguageModel] backed by the OpenAI chat completions API.
///
/// Point [baseUrl] at any OpenAI-compatible server, such as Ollama
/// (`http://localhost:11434/v1`), LM Studio or vLLM. Cancelling the stream
/// returned by [generate] aborts the HTTP request.
final class OpenAiModel implements LanguageModel {
  /// Creates a model that calls [model].
  ///
  /// [apiKey] may be omitted for local servers that need none. Pass a
  /// [client] to reuse connections, add a proxy or record traffic in tests.
  const factory({
    required String model,
    Secret? apiKey,
    Uri? baseUrl,
    http.Client? client,
    Map<String, String> headers,
  }) = OpenAiModel._;

  const new _({
    required this.model,
    this._apiKey,
    this.baseUrl,
    this._client,
    this.headers = const {},
  });

  /// Model name sent to the API, such as `gpt-4o-mini`.
  final String model;

  /// API root; defaults to `https://api.openai.com/v1/`.
  final Uri? baseUrl;

  /// Extra headers sent with every request.
  final Map<String, String> headers;

  final Secret? _apiKey;
  final http.Client? _client;

  @override
  String get id => 'openai/$model';

  @override
  Stream<ModelEvent> generate(ModelRequest request) {
    final decoder = OpenAiStreamDecoder();
    final transport = HttpTransport(provider: 'openai', client: _client);
    final body = transport.postJson(
      _endpoint(),
      headers: {
        ...headers,
        if (_apiKey case final key?) 'authorization': 'Bearer ${key.reveal()}',
        'accept': 'text/event-stream',
      },
      body: encodeChatRequest(model, request),
    );
    return body
        .transform(const SseDecoder())
        .takeWhile((event) => event.data != '[DONE]')
        .expand((event) => decoder.accept(jsonDecode(event.data)))
        .transform(appendOnDone(decoder.finish));
  }

  Uri _endpoint() {
    final root = baseUrl ?? Uri.parse('https://api.openai.com/v1/');
    final base = root.path.endsWith('/')
        ? root
        : root.replace(path: '${root.path}/');
    return base.resolve('chat/completions');
  }
}
