import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:jackdaw/jackdaw.dart';

/// An [Embedder] backed by the OpenAI embeddings API or a compatible
/// server.
final class OpenAiEmbedder implements Embedder {
  /// Creates an embedder that calls [model], such as
  /// `text-embedding-3-small`. [dimensions] shortens the vectors on models
  /// that support it.
  const factory({
    required String model,
    Secret? apiKey,
    Uri? baseUrl,
    http.Client? client,
    Map<String, String> headers,
    int? dimensions,
  }) = OpenAiEmbedder._;

  const new _({
    required this.model,
    this._apiKey,
    this.baseUrl,
    this._client,
    this.headers = const {},
    this.dimensions,
  });

  /// Model name sent to the API.
  final String model;

  /// API root; defaults to `https://api.openai.com/v1/`.
  final Uri? baseUrl;

  /// Extra headers sent with every request.
  final Map<String, String> headers;

  /// Requested vector size, when the model supports shortening.
  final int? dimensions;

  final Secret? _apiKey;
  final http.Client? _client;

  @override
  String get id => 'openai/$model';

  @override
  Future<List<Float32List>> embed(
    List<String> texts, {
    EmbeddingKind kind = EmbeddingKind.document,
  }) async {
    if (texts.isEmpty) return const [];
    final json = await HttpTransport(provider: 'openai', client: _client)
        .postForJson(
          resolveEndpoint(
            baseUrl ?? Uri.parse('https://api.openai.com/v1/'),
            'embeddings',
          ),
          headers: {
            ...headers,
            if (_apiKey case final key?)
              'authorization': 'Bearer ${key.reveal()}',
          },
          body: {
            'model': model,
            'input': texts,
            'encoding_format': 'float',
            'dimensions': ?dimensions,
          },
        );
    if (json case {'data': final List<Object?> data}
        when data.length == texts.length) {
      final items = [for (final item in data) item! as Map]
        ..sort((a, b) => (a['index'] as num).compareTo(b['index'] as num));
      return [for (final item in items) vectorFromJson(item['embedding'])];
    }
    throw const FormatException('unexpected embeddings response');
  }
}
