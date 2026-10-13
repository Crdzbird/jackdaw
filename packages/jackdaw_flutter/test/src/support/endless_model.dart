import 'dart:async';

import 'package:jackdaw/jackdaw.dart';

/// A model that streams `tick` forever until cancelled.
final class EndlessModel implements LanguageModel {
  /// Whether the stream was cancelled.
  bool cancelled = false;

  @override
  String get id => 'test/endless';

  @override
  Stream<ModelEvent> generate(ModelRequest request) {
    Timer? timer;
    late final StreamController<ModelEvent> controller;
    controller = StreamController<ModelEvent>(
      onListen: () => timer = Timer.periodic(
        const Duration(milliseconds: 5),
        (_) => controller.add(const TextDelta('tick ')),
      ),
      onCancel: () {
        cancelled = true;
        timer?.cancel();
      },
    );
    return controller.stream;
  }
}
