import 'dart:io';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/src/download/model_download_progress.dart';
import 'package:jackdaw_native/src/download/model_downloader.dart';
import 'package:jackdaw_native/src/download/model_file.dart';
import 'package:jackdaw_native/src/local_model_options.dart';
import 'package:jackdaw_native/src/native/native_generate_options.dart';
import 'package:jackdaw_native/src/native/native_model.dart';
import 'package:jackdaw_native/src/native/native_session.dart';
import 'package:jackdaw_native/src/native/native_stats.dart';

/// A [LanguageModel] that runs a GGUF model on the device.
///
/// Inference happens on a native worker thread. A request's response
/// schema is compiled to a grammar, so the model can only produce JSON that
/// matches it. Tools are offered the same way: the model either answers or
/// writes tool calls whose arguments match each tool's schema. Consecutive
/// turns reuse the cached prompt prefix.
final class LocalModel implements LanguageModel {
  new _(this.id, this._model, this._session);

  /// Loads the model at [path]; the file is read off the calling isolate.
  static Future<LocalModel> open(
    String path, {
    LocalModelOptions options = const LocalModelOptions(),
  }) async {
    final model = await NativeModel.load(
      path,
      gpuLayers: options.gpuLayers,
      mmap: options.mmap,
    );
    final session = NativeSession(model, options: options.session);
    final name = Uri.file(path).pathSegments.last;
    return LocalModel._('local/$name', model, session);
  }

  /// Loads [model], by default Qwen2.5 1.5B Instruct, from [directory],
  /// downloading and checking it there first when it is missing; see
  /// [ModelDownloader]. [onProgress] follows the download.
  static Future<LocalModel> download(
    Directory directory, {
    ModelFile model = ModelFile.qwen25Instruct,
    void Function(ModelDownloadProgress progress)? onProgress,
    LocalModelOptions options = const LocalModelOptions(),
  }) async {
    final file = await ModelDownloader(directory)
        .fetch(model, onProgress: onProgress);
    return await open(file.path, options: options);
  }

  @override
  final String id;

  final NativeModel _model;
  final NativeSession _session;

  /// Exact number of tokens [text] occupies for this model.
  int countTokens(String text) => _model.countTokens(text);

  /// Counts and timings of the last finished generation.
  NativeStats get stats => _session.stats;

  /// Completes once every request started so far has stopped natively.
  Future<void> get idle => _session.idle;

  @override
  Stream<ModelEvent> generate(ModelRequest request) {
    final schema = request.responseSchema;
    final tools = request.tools;
    final options = request.options;
    final events = _session.generate(
      _model.applyTemplate(localPrompt(request)),
      NativeGenerateOptions(
        temperature: options.temperature ?? 0,
        maxTokens: options.maxOutputTokens ?? 0,
        grammar: switch ((tools.isEmpty, schema)) {
          (false, _) => toolCallGrammar(tools, answer: schema),
          (true, final Schema schema) => GbnfCompiler().compile(schema),
          (true, null) => null,
        },
      ),
    );
    return tools.isEmpty ? events : events.transform(ToolCallDecoder());
  }

  /// Frees the session and the model. The model must not be used after.
  void close() {
    _session.dispose();
    _model.dispose();
  }
}
