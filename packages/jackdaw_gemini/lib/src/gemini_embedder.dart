import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:jackdaw/jackdaw.dart';

/// An [Embedder] backed by the Gemini `batchEmbedContents` API.
///
/// Documents and queries are sent with the `RETRIEVAL_DOCUMENT` and
/// `RETRIEVAL_QUERY` task types, which Gemini embeds differently.
final class GeminiEmbedder implements Embedder {
  /// Creates an embedder that calls [model], such as
  /// `gemini-embedding-001`. [dimensions] shortens the vectors.
  const factory({
    required String model,
    required Secret apiKey,
    Uri? baseUrl,
    http.Client? client,
    Map<String, String> headers,
    int? dimensions,
  }) = GeminiEmbedder._;

  const new _({
    required this.model,
    required this._apiKey,
    this.baseUrl,
    this._client,
    this.headers = const {},
    this.dimensions,
  });

  /// Model name, without the `models/` prefix.
  final String model;

  /// API root; defaults to the public `v1beta` endpoint.
  final Uri? baseUrl;

  /// Extra headers sent with every request.
  final Map<String, String> headers;

  /// Requested vector size, sent as `outputDimensionality`.
  final int? dimensions;

  final Secret _apiKey;
  final http.Client? _client;

  @override
  String get id => 'gemini/$model';

  @override
  Future<List<Float32List>> embed(
    List<String> texts, {
    EmbeddingKind kind = EmbeddingKind.document,
  }) async {
    if (texts.isEmpty) return const [];
    final task = kind == EmbeddingKind.query
        ? 'RETRIEVAL_QUERY'
        : 'RETRIEVAL_DOCUMENT';
    final json = await HttpTransport(provider: 'gemini', client: _client)
        .postForJson(
          resolveEndpoint(
            baseUrl ??
                Uri.parse('https://generativelanguage.googleapis.com/v1beta/'),
            'models/$model:batchEmbedContents',
          ),
          headers: {...headers, 'x-goog-api-key': _apiKey.reveal()},
          body: {
            'requests': [
              for (final text in texts)
                {
                  'model': 'models/$model',
                  'content': {
                    'parts': [
                      {'text': text},
                    ],
                  },
                  'taskType': task,
                  'outputDimensionality': ?dimensions,
                },
            ],
          },
        );
    if (json case {'embeddings': final List<Object?> items}
        when items.length == texts.length) {
      return [
        for (final item in items) vectorFromJson((item! as Map)['values']),
      ];
    }
    throw const FormatException('unexpected embeddings response');
  }
}
