import 'package:jackdaw/jackdaw.dart';

/// A model that answers from the transcript instead of a script, so it can
/// be called again after an interruption: it asks for its calls when the last
/// message is from the user and answers [answer] otherwise.
final class ReactiveModel implements LanguageModel {
  factory(List<ToolCallPart> calls, {String answer}) = ReactiveModel._;

  new _(this._calls, {this.answer = 'done'});

  final List<ToolCallPart> _calls;
  final String answer;
  int requests = 0;

  @override
  String get id => 'test/reactive';

  @override
  Stream<ModelEvent> generate(ModelRequest request) {
    requests++;
    final last = request.messages.isEmpty ? null : request.messages.last;
    if (last?.role == Role.user) {
      return Stream.fromIterable([
        for (final call in _calls) ToolCallEvent(call),
        const FinishEvent(reason: FinishReason.toolCalls),
      ]);
    }
    return Stream.fromIterable([
      TextDelta(answer),
      const FinishEvent(reason: FinishReason.stop),
    ]);
  }
}
