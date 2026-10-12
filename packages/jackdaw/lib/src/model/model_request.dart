import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/model/generation_options.dart';
import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/tool/tool_spec.dart';

/// Everything a language model needs for one call.
final class ModelRequest {
  /// Creates a request for [messages] with the [tools] the model may call.
  const factory({
    required List<Message> messages,
    List<ToolSpec> tools,
    GenerationOptions options,
    Schema? responseSchema,
  }) = ModelRequest._;

  const new _({
    required this.messages,
    this.tools = const [],
    this.options = const GenerationOptions(),
    this.responseSchema,
  });

  /// The conversation so far, oldest first.
  final List<Message> messages;

  /// Tools the model may ask to run.
  final List<ToolSpec> tools;

  /// Sampling settings.
  final GenerationOptions options;

  /// Shape the answer must have, when structured output is wanted.
  final Schema? responseSchema;
}
