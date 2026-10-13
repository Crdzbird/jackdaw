import 'package:jackdaw/jackdaw.dart';

/// The tool offered in `ContractCase.toolCall`.
const ToolSpec contractTool = ToolSpec(
  name: 'ping',
  description: 'Sends a short text to the test server',
  input: ObjectSchema(
    properties: {'text': Schema.string()},
    required: ['text'],
  ),
);

/// The schema of `ContractCase.schema`.
const ObjectSchema contractSchema = ObjectSchema(
  properties: {'answer': Schema.string(), 'sure': Schema.boolean()},
  required: ['answer', 'sure'],
);

/// The request each contract case sends.
ModelRequest contractRequest(String prompt, {int limit = 64}) => ModelRequest(
  messages: [Message.user(prompt)],
  options: GenerationOptions(maxOutputTokens: limit, temperature: 0),
);
