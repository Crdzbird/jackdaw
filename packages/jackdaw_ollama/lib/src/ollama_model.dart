import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_ollama/src/ollama_request_encoder.dart';
import 'package:jackdaw_ollama/src/ollama_stream_decoder.dart';

/// A [LanguageModel] backed by Ollama's native `/api/chat` endpoint.
///
/// Unlike the OpenAI-compatible endpoint, this one exposes the context
/// size ([numCtx]), [topK] and [keepAlive]. Cancelling the stream aborts
/// the request.
final class OllamaModel implements LanguageModel {
  /// Creates a model that calls [model], such as `qwen2.5:3b-instruct`.
  const factory({
    required String model,
    Uri? baseUrl,
    http.Client? client,
    Map<String, String> headers,
    int? numCtx,
    int? topK,
    String? keepAlive,
  }) = OllamaModel._;

  const new _({
    required this.model,
    this.baseUrl,
    this._client,
    this.headers = const {},
    this.numCtx,
    this.topK,
    this.keepAlive,
  });

  /// Model name, including its tag.
  final String model;

  /// Server root; defaults to `http://localhost:11434/`.
  final Uri? baseUrl;

  /// Extra headers, for example for an authenticating proxy.
  final Map<String, String> headers;

  /// Context window in tokens (`num_ctx`).
  final int? numCtx;

  /// Top-k sampling cut-off.
  final int? topK;

  /// How long the server keeps the model loaded, such as `5m`.
  final String? keepAlive;

  final http.Client? _client;

  @override
  String get id => 'ollama/$model';

  @override
  Stream<ModelEvent> generate(ModelRequest request) {
    final decoder = OllamaStreamDecoder();
    final root = baseUrl ?? Uri.parse('http://localhost:11434/');
    final base = root.path.endsWith('/')
        ? root
        : root.replace(path: '${root.path}/');
    final body = HttpTransport(provider: 'ollama', client: _client).postJson(
      base.resolve('api/chat'),
      headers: headers,
      body: encodeChatRequest(
        model,
        request,
        numCtx: numCtx,
        topK: topK,
        keepAlive: keepAlive,
      ),
    );
    return body
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where((line) => line.trim().isNotEmpty)
        .expand((line) => decoder.accept(jsonDecode(line)))
        .transform(appendOnDone(decoder.finish));
  }
}
