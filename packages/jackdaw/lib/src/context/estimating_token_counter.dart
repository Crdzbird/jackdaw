import 'package:jackdaw/src/context/message_content.dart';
import 'package:jackdaw/src/context/token_counter.dart';
import 'package:jackdaw/src/message/message.dart';

/// Approximates tokens from text length, rounding up.
final class EstimatingTokenCounter implements TokenCounter {
  /// Creates an estimator with [charsPerToken] characters per token.
  const factory({double charsPerToken, int overhead}) =
      EstimatingTokenCounter._;

  const new _({this.charsPerToken = 3.5, this.overhead = 4});

  /// Average characters per token; lower values over-count, which is safer.
  final double charsPerToken;

  /// Tokens added per message for role and formatting markers.
  final int overhead;

  @override
  int count(Message message) =>
      (messageContent(message).length / charsPerToken).ceil() + overhead;
}
