import 'package:jackdaw/jackdaw.dart';

/// A model whose every call fails.
final class BrokenModel implements LanguageModel {
  @override
  String get id => 'test/broken';

  @override
  Stream<ModelEvent> generate(ModelRequest request) =>
      Stream.error(StateError('model offline'));
}
