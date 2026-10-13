import 'package:jackdaw/src/context/estimating_token_counter.dart';
import 'package:jackdaw/src/context/token_counter.dart';
import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/message/role.dart';

/// Keeps the messages sent to a model within [maxTokens].
///
/// The oldest messages are dropped first, and a trimmed transcript always
/// starts at a user message, so a tool result is never separated from the
/// call that produced it. The latest user turn and everything after it are
/// always kept. Only the request is trimmed; the session
/// journal keeps every message.
final class ContextBudget {
  /// Creates a budget of [maxTokens] measured with [counter].
  const factory({required int maxTokens, TokenCounter counter}) =
      ContextBudget._;

  const new _({
    required this.maxTokens,
    this.counter = const EstimatingTokenCounter(),
  });

  /// Upper bound for the transcript sent with a request.
  final int maxTokens;

  /// How messages are measured.
  final TokenCounter counter;

  /// Returns the newest messages of [messages] that fit the budget.
  List<Message> fit(List<Message> messages) {
    final lastUser = messages.lastIndexWhere((m) => m.role == Role.user);
    var start = 0;
    var total = messages.fold(0, (sum, m) => sum + counter.count(m));
    while (start < lastUser &&
        (total > maxTokens || messages[start].role != Role.user)) {
      if (total <= maxTokens && start == 0) break;
      total -= counter.count(messages[start]);
      start++;
    }
    return messages.sublist(start);
  }
}
