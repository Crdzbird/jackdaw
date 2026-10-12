import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/message/role.dart';

/// A single turn in a conversation.
final class Message {
  /// Creates a message authored by [role] made of [parts].
  const factory({required Role role, required List<Part> parts}) = Message._;

  const new _({required this.role, required this.parts});

  /// Creates a system message holding [text].
  factory system(String text) =>
      Message(role: Role.system, parts: [TextPart(text)]);

  /// Creates a user message holding [text].
  factory user(String text) =>
      Message(role: Role.user, parts: [TextPart(text)]);

  /// Creates an assistant message holding [text].
  factory assistant(String text) =>
      Message(role: Role.assistant, parts: [TextPart(text)]);

  /// Who authored the message.
  final Role role;

  /// The content of the message, in order.
  final List<Part> parts;

  /// All text parts joined together.
  String get text => parts.whereType<TextPart>().map((p) => p.text).join();

  /// The tool calls contained in this message.
  List<ToolCallPart> get toolCalls =>
      parts.whereType<ToolCallPart>().toList(growable: false);
}
