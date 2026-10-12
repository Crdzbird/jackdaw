part 'text_part.dart';
part 'tool_call_part.dart';
part 'tool_result_part.dart';

/// One piece of content inside a message.
///
/// The hierarchy is sealed so every consumer can switch over it
/// exhaustively.
sealed class Part {
  const new _();
}
