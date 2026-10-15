import 'dart:io';

import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/src/download/model_download_progress.dart';
import 'package:jackdaw_native/src/download/model_downloader.dart';
import 'package:jackdaw_native/src/download/model_file.dart';
import 'package:jackdaw_native/src/local_model_options.dart';
import 'package:jackdaw_native/src/local_request.dart';
import 'package:jackdaw_native/src/native/native_features.dart';
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

  /// Writes what the model has processed so far, such as a long system
  /// prompt, to [file], after the requests already started. A later run
  /// that calls [loadState] with it skips processing that text again.
  Future<void> saveState(File file) => _session.save(file.path);

  /// Restores what [saveState] wrote to [file], so a prompt that starts
  /// with the same text only processes the rest. Returns the number of
  /// tokens restored, or 0 when the file is missing or from another model.
  Future<int> loadState(File file) => _session.load(file.path);

  /// Streams the answer to [request]. The chat template is rendered on
  /// the native worker when the library can, not on the calling isolate.
  @override
  Stream<ModelEvent> generate(ModelRequest request) {
    final messages = localPrompt(request);
    final options = localOptions(request);
    final events = nativeChat
        ? _session.generateChat(messages, options)
        : _session.generate(_model.applyTemplate(messages), options);
    return request.tools.isEmpty ? events : events.transform(ToolCallDecoder());
  }

  /// Frees the session and the model. The model must not be used after.
  void close() {
    _session.dispose();
    _model.dispose();
  }
}
