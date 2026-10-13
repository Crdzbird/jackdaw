import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/message/role.dart';

/// Encodes [message] as JSON-compatible data for session storage.
Map<String, Object?> messageToJson(Message message) => {
  'role': message.role.name,
  'parts': [for (final part in message.parts) _part(part)],
};

/// Decodes a message written by [messageToJson].
Message messageFromJson(Map<String, Object?> json) => Message(
  role: Role.values.byName(json['role']! as String),
  parts: [
    for (final part in json['parts']! as List<Object?>)
      _readPart(part! as Map<String, Object?>),
  ],
);

Map<String, Object?> _part(Part part) => switch (part) {
  TextPart(:final text) => {'type': 'text', 'text': text},
  ReasoningPart(:final provider, :final text, :final data) => {
    'type': 'reasoning',
    'provider': provider,
    'text': text,
    'data': data,
  },
  ToolCallPart(:final id, :final name, :final arguments, :final providerData) =>
    {
      'type': 'toolCall',
      'id': id,
      'name': name,
      'arguments': arguments,
      'providerData': providerData,
    },
  ToolResultPart(:final callId, :final name, :final output, :final isError) => {
    'type': 'toolResult',
    'callId': callId,
    'name': name,
    'output': output,
    'isError': isError,
  },
};

Part _readPart(Map<String, Object?> json) => switch (json['type']) {
  'text' => TextPart(json['text']! as String),
  'reasoning' => ReasoningPart(
    provider: json['provider']! as String,
    text: json['text']! as String,
    data: Map<String, Object?>.from(json['data']! as Map),
  ),
  'toolCall' => ToolCallPart(
    id: json['id']! as String,
    name: json['name']! as String,
    arguments: json['arguments'],
    providerData: Map<String, Object?>.from(json['providerData']! as Map),
  ),
  _ => ToolResultPart(
    callId: json['callId']! as String,
    name: json['name']! as String,
    output: json['output'],
    isError: json['isError']! as bool,
  ),
};
