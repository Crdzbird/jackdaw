import 'dart:convert';

import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/message/part.dart';

/// Everything in [message] that the model reads, as one text: text,
/// reasoning, tool arguments and tool results.
String messageContent(Message message) => [
  for (final part in message.parts)
    switch (part) {
      TextPart(:final text) => text,
      ReasoningPart(:final text) => text,
      ToolCallPart(:final name, :final arguments) =>
        '$name ${jsonEncode(arguments)}',
      ToolResultPart(:final output) => jsonEncode(output),
    },
].join('\n');
