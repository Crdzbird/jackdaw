import 'dart:async';
import 'dart:js_interop';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_openai/wire.dart';
import 'package:jackdaw_web/src/chat_options.dart';
import 'package:jackdaw_web/src/js/abort_controller.dart';
import 'package:jackdaw_web/src/js/wllama.dart';
import 'package:jackdaw_web/src/js/wllama_module.dart';

/// A [LanguageModel] that runs a GGUF model in the browser with wllama.
///
/// Prompts, tool calls and response schemas use the same format and GBNF
/// grammars as the native core, so structured output and tool use behave
/// alike on every platform.
/// Cancelling the stream aborts generation.
final class WebLocalModel implements LanguageModel {
  new _(this.id, this._wllama);

  /// Loads wllama from [moduleUrl] and [wasmUrl], then the model at
  /// [modelUrl].
  ///
  /// Host the wllama files yourself or point at a pinned CDN copy; nothing
  /// is fetched implicitly. Models larger than 2 GB must be split.
  static Future<WebLocalModel> open({
    required String modelUrl,
    required String moduleUrl,
    required String wasmUrl,
    int contextTokens = 4096,
  }) async {
    final module = await WllamaModule.load(moduleUrl);
    final wllama = module.create(wasmUrl);
    final params = {'n_ctx': contextTokens}.jsify()! as JSObject;
    await wllama.loadModelFromUrl(modelUrl.toJS, params).toDart;
    final name = Uri.parse(modelUrl).pathSegments.last;
    return WebLocalModel._('web/$name', wllama);
  }

  @override
  final String id;

  final Wllama _wllama;

  @override
  Stream<ModelEvent> generate(ModelRequest request) {
    final events = _stream(request);
    return request.tools.isEmpty ? events : events.transform(ToolCallDecoder());
  }

  Stream<ModelEvent> _stream(ModelRequest request) async* {
    final decoder = OpenAiStreamDecoder();
    final chunks = StreamController<Object?>();
    final abort = AbortController();
    final options = chatOptions(request, abort.signal, chunks.add);
    final pumping = _wllama
        .createChatCompletion(options)
        .toDart
        .then(
          (_) => chunks.close(),
          onError: (Object error) => _fail(chunks, error),
        );
    var finished = false;
    try {
      yield* chunks.stream.expand(decoder.accept);
      await pumping;
      yield* Stream.fromIterable(decoder.finish());
      finished = true;
    } finally {
      if (!finished) abort.abort();
    }
  }

  /// Unloads the model and frees its memory.
  Future<void> close() async {
    await _wllama.exit().toDart;
  }

  static Future<void> _fail(StreamController<Object?> chunks, Object error) {
    chunks.addError(ProviderException(provider: 'wllama', message: '$error'));
    return chunks.close();
  }
}
