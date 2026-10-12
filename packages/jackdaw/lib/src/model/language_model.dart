import 'package:jackdaw/src/model/model_event.dart';
import 'package:jackdaw/src/model/model_request.dart';

/// A model that turns a conversation into a stream of events.
///
/// Implementations must stop all work, including network requests or native
/// decoding, when the returned stream's subscription is cancelled.
abstract interface class LanguageModel {
  /// Stable identifier such as `openai/gpt-4o-mini`.
  String get id;

  /// Streams the model's answer to [request].
  ///
  /// The stream ends with exactly one [FinishEvent] on success.
  Stream<ModelEvent> generate(ModelRequest request);
}
