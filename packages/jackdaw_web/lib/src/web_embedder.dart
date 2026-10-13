import 'dart:js_interop';
import 'dart:typed_data';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_web/src/js/wllama.dart';
import 'package:jackdaw_web/src/js/wllama_module.dart';

/// An [Embedder] that runs a GGUF embedding model in the browser with
/// wllama. Vectors are scaled to unit length, like the native embedder's.
///
/// Texts are sent one per call, because wllama 3.8 embeds only the first
/// text of a list.
final class WebEmbedder implements Embedder {
  new _(this.id, this._wllama, this.queryPrefix, this.documentPrefix);

  /// Loads wllama from [moduleUrl] and [wasmUrl], then the embedding model
  /// at [modelUrl]. [pooling] overrides the model's pooling, for example
  /// `mean`; by default the model's own setting is used.
  static Future<WebEmbedder> open({
    required String modelUrl,
    required String moduleUrl,
    required String wasmUrl,
    int contextTokens = 512,
    String? pooling,
    String queryPrefix = '',
    String documentPrefix = '',
  }) async {
    final wllama = (await WllamaModule.load(moduleUrl)).create(wasmUrl);
    final params = {
      'n_ctx': contextTokens,
      'embeddings': true,
      'pooling_type': ?pooling,
    };
    await wllama
        .loadModelFromUrl(modelUrl.toJS, params.jsify()! as JSObject)
        .toDart;
    final name = Uri.parse(modelUrl).pathSegments.last;
    return WebEmbedder._('web/$name', wllama, queryPrefix, documentPrefix);
  }

  @override
  final String id;

  /// Text put before every query.
  final String queryPrefix;

  /// Text put before every document.
  final String documentPrefix;

  final Wllama _wllama;
  Future<void> _last = Future.value();

  @override
  Future<List<Float32List>> embed(
    List<String> texts, {
    EmbeddingKind kind = EmbeddingKind.document,
  }) async {
    if (texts.isEmpty) return const [];
    final prefix = kind == EmbeddingKind.query ? queryPrefix : documentPrefix;
    final input = [for (final text in texts) '$prefix$text'];
    final run = _last.then((_) => _embed(input));
    _last = run.then<void>((_) {}, onError: (Object _) {});
    return await run;
  }

  Future<List<Float32List>> _embed(List<String> input) async => [
    for (final text in input) await _embedOne(text),
  ];

  Future<Float32List> _embedOne(String text) async {
    final options = {'input': text}.jsify()! as JSObject;
    final Object? response;
    try {
      response = (await _wllama.createEmbedding(options).toDart).dartify();
    } on Object catch (error) {
      throw ProviderException(provider: 'wllama', message: '$error');
    }
    if (response case {'data': [{'embedding': final Object? vector}, ...]}) {
      return normalized(vectorFromJson(vector));
    }
    throw const FormatException('unexpected embeddings response');
  }

  /// Unloads the model and frees its memory.
  Future<void> close() async {
    await _last;
    await _wllama.exit().toDart;
  }
}
