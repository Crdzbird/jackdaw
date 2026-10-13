import 'package:jackdaw/src/context/message_content.dart';
import 'package:jackdaw/src/context/token_counter.dart';
import 'package:jackdaw/src/message/message.dart';

/// Counts tokens with a tokenizer function, such as a local model's.
final class TextTokenCounter implements TokenCounter {
  /// Counts with [_count], adding [overhead] tokens per message.
  factory(int Function(String text) count, {int overhead}) = TextTokenCounter._;

  new _(this._count, {this.overhead = 4});

  final int Function(String text) _count;

  /// Tokens added per message for role and formatting markers.
  final int overhead;

  @override
  int count(Message message) => _count(messageContent(message)) + overhead;
}
