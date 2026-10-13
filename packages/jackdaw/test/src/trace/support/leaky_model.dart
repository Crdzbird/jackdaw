import 'package:jackdaw/jackdaw.dart';

/// A model that repeats [secret] in its tool calls and answers, and can be
/// told to fail with an error that mentions it.
final class LeakyModel implements LanguageModel {
  factory(String secret, {bool fail}) = LeakyModel._;

  new _(this.secret, {this.fail = false});

  final String secret;
  final bool fail;

  @override
  String get id => 'test/leaky';

  @override
  Stream<ModelEvent> generate(ModelRequest request) {
    if (fail) return Stream.error(StateError('auth failed for $secret'));
    if (request.messages.last.role == Role.user) {
      return Stream.fromIterable([
        ToolCallEvent(
          ToolCallPart(id: 'c1', name: 'lookup', arguments: {'key': secret}),
        ),
        ToolCallEvent(
          ToolCallPart(id: 'c2', name: 'explode', arguments: {'key': secret}),
        ),
        const FinishEvent(
          reason: FinishReason.toolCalls,
          usage: Usage(inputTokens: 10, outputTokens: 4),
        ),
      ]);
    }
    return Stream.fromIterable([
      TextDelta('the key is $secret'),
      const FinishEvent(
        reason: FinishReason.stop,
        usage: Usage(inputTokens: 20, outputTokens: 5),
      ),
    ]);
  }
}
