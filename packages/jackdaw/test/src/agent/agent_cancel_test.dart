import 'dart:async';

import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

final class HangingModel implements LanguageModel {
  final Completer<void> cancelled = Completer<void>();

  @override
  String get id => 'test/hanging';

  @override
  Stream<ModelEvent> generate(ModelRequest request) {
    final controller = StreamController<ModelEvent>();
    controller
      ..onListen = (() => controller.add(const TextDelta('partial')))
      ..onCancel = cancelled.complete;
    return controller.stream;
  }
}

void main() {
  test('cancelling the run cancels the model call', () async {
    final model = HangingModel();
    final first = await Agent(model: model).run([Message.user('go')]).first;
    await model.cancelled.future;
    expect((first as AgentTextDelta).text, 'partial');
    expect(model.cancelled.isCompleted, isTrue);
    expect(model.id, 'test/hanging');
  });
}
