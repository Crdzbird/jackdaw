import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/src/ffi/jackdaw_bindings.g.dart';
import 'package:jackdaw_native/src/native/create_embedder.dart';
import 'package:jackdaw_native/src/native/embed_texts.dart';
import 'package:jackdaw_native/src/native/native_model.dart';

/// An [Embedder] that runs a GGUF embedding model on the device.
///
/// Work runs on background isolates, one batch at a time. Texts longer
/// than the token limit given to [create] are cut. Some models expect a
/// marker before each text; set [queryPrefix] and [documentPrefix] for
/// those, for example `search_query: ` and `search_document: `.
final class NativeEmbedder implements Embedder {
  new _(
    this._address,
    this.dimensions,
    this.id,
    this.queryPrefix,
    this.documentPrefix,
  );

  /// Creates an embedder on [model], which must outlive it.
  static Future<NativeEmbedder> create(
    NativeModel model, {
    int maxTokens = 512,
    int threads = 0,
    String id = 'local/embedder',
    String queryPrefix = '',
    String documentPrefix = '',
  }) async {
    final modelAddress = model.pointer.address;
    final (address, dimensions) = await Isolate.run(
      () => createEmbedder(modelAddress, maxTokens, threads),
    );
    return NativeEmbedder._(
      address,
      dimensions,
      id,
      queryPrefix,
      documentPrefix,
    );
  }

  final int _address;
  Future<void> _last = Future.value();
  bool _disposed = false;

  /// Number of components in every vector.
  final int dimensions;

  @override
  final String id;

  /// Text put before every query.
  final String queryPrefix;

  /// Text put before every document.
  final String documentPrefix;

  @override
  Future<List<Float32List>> embed(
    List<String> texts, {
    EmbeddingKind kind = EmbeddingKind.document,
  }) async {
    if (_disposed) throw StateError('embedder disposed');
    final prefix = kind == EmbeddingKind.query ? queryPrefix : documentPrefix;
    final prefixed = [for (final text in texts) '$prefix$text'];
    final address = _address;
    final width = dimensions;
    final run = _last.then(
      (_) => Isolate.run(() => embedTexts(address, width, prefixed)),
    );
    _last = run.then<void>((_) {}, onError: (Object _) {});
    return await run;
  }

  /// Waits for running work, then frees the embedder.
  Future<void> dispose() async {
    _disposed = true;
    await _last;
    jackdaw_embedder_free(Pointer.fromAddress(_address));
  }
}
