import 'dart:convert';

import 'package:jackdaw/jackdaw.dart';

/// A model that answers each request with the next of [replies], encoded
/// as JSON, and keeps the requests it saw.
final class RepliesModel implements LanguageModel {
  factory(List<Object?> replies) = RepliesModel._;

  new _(this.replies);

  final List<Object?> replies;
  final List<ModelRequest> requests = [];

  @override
  String get id => 'test/replies';

  @override
  Stream<ModelEvent> generate(ModelRequest request) {
    requests.add(request);
    return Stream.fromIterable([
      TextDelta(jsonEncode(replies[requests.length - 1])),
      const FinishEvent(reason: FinishReason.stop),
    ]);
  }
}
