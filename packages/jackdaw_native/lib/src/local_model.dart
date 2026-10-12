import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/src/local_model_options.dart';
import 'package:jackdaw_native/src/native/native_generate_options.dart';
import 'package:jackdaw_native/src/native/native_model.dart';
import 'package:jackdaw_native/src/native/native_session.dart';
import 'package:jackdaw_native/src/native/native_stats.dart';
import 'package:jackdaw_native/src/template_messages.dart';

/// A [LanguageModel] that runs a GGUF model on the device.
///
/// Inference happens on a native worker thread. A request's response
/// schema is compiled to a grammar, so the model can only produce JSON that
/// matches it. Consecutive turns reuse the cached prompt prefix.
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
    if (request.tools.isNotEmpty) {
      return Stream.error(UnsupportedError('LocalModel cannot run tools yet'));
    }
    final schema = request.responseSchema;
    final prompt = _model.applyTemplate(
      templateMessages(request.messages, schema),
    );
    final options = request.options;
    return _session.generate(
      prompt,
      NativeGenerateOptions(
        temperature: options.temperature ?? 0,
        maxTokens: options.maxOutputTokens ?? 0,
        grammar: schema == null ? null : GbnfCompiler().compile(schema),
      ),
    );
  }

  /// Frees the session and the model. The model must not be used after.
  void close() {
    _session.dispose();
    _model.dispose();
  }
}
