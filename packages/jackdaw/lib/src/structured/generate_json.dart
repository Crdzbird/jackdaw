import 'dart:convert';

import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/model/generation_options.dart';
import 'package:jackdaw/src/model/language_model.dart';
import 'package:jackdaw/src/model/model_event.dart';
import 'package:jackdaw/src/model/model_request.dart';
import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/structured/structured_output_exception.dart';

/// Asks [model] for JSON matching [schema] and returns the decoded value.
///
/// The schema is sent as the request's response schema, so models that
/// support constrained decoding are held to it while generating. The answer
/// is always parsed and validated offline afterwards; any problem throws a
/// [StructuredOutputException].
Future<Object?> generateJson(
  LanguageModel model,
  List<Message> messages,
  Schema schema, {
  GenerationOptions options = const GenerationOptions(),
}) async {
  final request = ModelRequest(
    messages: messages,
    options: options,
    responseSchema: schema,
  );
  final events = await model.generate(request).toList();
  final text = events.whereType<TextDelta>().map((e) => e.text).join();
  final Object? value;
  try {
    value = jsonDecode(text);
  } on FormatException {
    throw StructuredOutputException(text: text, violations: const []);
  }
  final violations = schema.validate(value);
  if (violations.isNotEmpty) {
    throw StructuredOutputException(text: text, violations: violations);
  }
  return value;
}
