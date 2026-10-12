import 'package:jackdaw/jackdaw.dart';

/// Builds the JSON body of a `streamGenerateContent` request.
///
/// Gemini reasoning parts and function-call signatures recorded earlier are
/// sent back unchanged. Tool results go back as `functionResponse` parts.
Map<String, Object?> encodeGenerateRequest(ModelRequest request) {
  final system = [
    for (final m in request.messages)
      if (m.role == Role.system) {'text': m.text},
  ];
  final options = request.options;
  final schema = request.responseSchema;
  final config = {
    'temperature': ?options.temperature,
    'maxOutputTokens': ?options.maxOutputTokens,
    if (schema != null) 'responseMimeType': 'application/json',
    'responseJsonSchema': ?schema?.toJson(),
  };
  return {
    'contents': [
      for (final m in request.messages)
        if (m.role != Role.system) _content(m),
    ],
    if (system.isNotEmpty) 'systemInstruction': {'parts': system},
    if (request.tools.isNotEmpty)
      'tools': [
        {
          'functionDeclarations': [
            for (final tool in request.tools)
              {
                'name': tool.name,
                'description': tool.description,
                'parametersJsonSchema': tool.input.toJson(),
              },
          ],
        },
      ],
    if (config.isNotEmpty) 'generationConfig': config,
  };
}

Map<String, Object?> _content(Message message) => {
  'role': message.role == Role.assistant ? 'model' : 'user',
  'parts': [for (final part in message.parts) ?_part(part)],
};

Map<String, Object?>? _part(Part part) => switch (part) {
  TextPart(:final text) when text.isNotEmpty => {'text': text},
  TextPart() => null,
  ReasoningPart(provider: 'gemini', :final data) => data,
  ReasoningPart() => null,
  ToolCallPart(:final id, :final name, :final arguments, :final providerData) =>
    {
      'functionCall': {
        'id': id,
        'name': name,
        'args': arguments is Map ? arguments : <String, Object?>{},
      },
      ...providerData,
    },
  ToolResultPart(:final callId, :final name, :final output) => {
    'functionResponse': {
      'id': callId,
      'name': name,
      'response': output is Map ? output : {'result': output},
    },
  },
};
