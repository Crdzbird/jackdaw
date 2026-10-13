import 'dart:async';

import 'package:jackdaw/jackdaw.dart';

/// A model whose single answer the test feeds event by event.
final class ManualModel implements LanguageModel {
  /// Receives the events of the current answer.
  final StreamController<ModelEvent> events = StreamController();

  @override
  String get id => 'test/manual';

  @override
  Stream<ModelEvent> generate(ModelRequest request) => events.stream;
}
