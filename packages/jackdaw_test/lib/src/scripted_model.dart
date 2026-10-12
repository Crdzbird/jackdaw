import 'package:jackdaw/jackdaw.dart';

/// A [LanguageModel] that replays prepared turns and records every request.
///
/// Each call to [generate] consumes the next turn. Calling it after the
/// script is exhausted yields a stream that fails with a [StateError].
final class ScriptedModel implements LanguageModel {
  /// Creates a model that answers with [turns], one per call.
  factory(List<List<ModelEvent>> turns, {String id}) = ScriptedModel._;

  new _(this._turns, {this.id = 'test/scripted'});

  final List<List<ModelEvent>> _turns;

  @override
  final String id;

  /// Requests received so far, oldest first.
  final List<ModelRequest> requests = [];

  /// Number of turns not yet consumed.
  int get remaining => _turns.length - requests.length;

  @override
  Stream<ModelEvent> generate(ModelRequest request) {
    if (remaining <= 0) {
      return Stream.error(StateError('no scripted turn for request $request'));
    }
    final turn = _turns[requests.length];
    requests.add(request);
    return Stream.fromIterable(turn);
  }
}
