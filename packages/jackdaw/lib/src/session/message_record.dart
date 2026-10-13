part of 'session_record.dart';

/// A message was added to the transcript.
final class MessageRecord extends SessionRecord {
  /// Records [message].
  const factory(Message message) = MessageRecord._;

  const new _(this.message) : super._();

  /// The message.
  final Message message;
}
