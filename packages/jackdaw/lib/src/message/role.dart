import 'package:jackdaw/jackdaw.dart' show Message;
import 'package:jackdaw/src/message/message.dart' show Message;

/// Who authored a [Message] in a conversation.
enum Role {
  /// Instructions that frame the whole conversation.
  system,

  /// Input written by the person using the app.
  user,

  /// Output produced by the model.
  assistant,

  /// Results returned by tools the model asked to run.
  tool,
}
