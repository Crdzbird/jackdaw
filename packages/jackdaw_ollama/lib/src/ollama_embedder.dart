import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:jackdaw/jackdaw.dart';

/// An [Embedder] backed by Ollama's native `/api/embed` endpoint.
///
/// Some models expect a marker before each text, such as `search_query: `
/// and `search_document: ` for nomic-embed-text; set [queryPrefix] and
/// [documentPrefix] for those.
final class OllamaEmbedder implements Embedder {
  /// Creates an embedder that calls [model], such as `nomic-embed-text`.
  const factory({
    required String model,
    Uri? baseUrl,
    http.Client? client,
    Map<String, String> headers,
    String queryPrefix,
    String documentPrefix,
  }) = OllamaEmbedder._;

  const new _({
    required this.model,
    this.baseUrl,
    this._client,
    this.headers = const {},
    this.queryPrefix = '',
    this.documentPrefix = '',
  });

  /// Model name, as listed by `ollama list`.
  final String model;

  /// Server root; defaults to `http://localhost:11434/`.
  final Uri? baseUrl;

  /// Extra headers sent with every request.
  final Map<String, String> headers;

  /// Text put before every query.
  final String queryPrefix;

  /// Text put before every document.
  final String documentPrefix;

  final http.Client? _client;

  @override
  String get id => 'ollama/$model';

  @override
  Future<List<Float32List>> embed(
    List<String> texts, {
    EmbeddingKind kind = EmbeddingKind.document,
  }) async {
    if (texts.isEmpty) return const [];
    final prefix = kind == EmbeddingKind.query ? queryPrefix : documentPrefix;
    final json = await HttpTransport(provider: 'ollama', client: _client)
        .postForJson(
          resolveEndpoint(
            baseUrl ?? Uri.parse('http://localhost:11434/'),
            'api/embed',
          ),
          headers: headers,
          body: {
            'model': model,
            'input': [for (final text in texts) '$prefix$text'],
          },
        );
    if (json case {'embeddings': final List<Object?> items}
        when items.length == texts.length) {
      return [for (final item in items) vectorFromJson(item)];
    }
    throw const FormatException('unexpected embeddings response');
  }
}
