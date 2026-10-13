import 'package:jackdaw/src/context/estimating_token_counter.dart';
import 'package:jackdaw/src/context/text_token_counter.dart';
import 'package:jackdaw/src/message/message.dart';

/// Counts the tokens a message occupies for a model.
abstract interface class TokenCounter {
  /// Counts with [count], a function giving the tokens of a text, such as
  /// `LocalModel.countTokens`, plus [overhead] tokens per message.
  factory fromText(int Function(String text) count, {int overhead}) =
      TextTokenCounter;

  /// Approximates one token per [charsPerToken] characters, for models
  /// whose tokenizer is not available offline.
  factory estimate({double charsPerToken, int overhead}) =
      EstimatingTokenCounter;

  /// Tokens used by [message].
  int count(Message message);
}
