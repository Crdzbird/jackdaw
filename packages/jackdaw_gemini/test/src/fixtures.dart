import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_gemini/jackdaw_gemini.dart';

/// Streams [chunks] as SSE through a [GeminiModel].
Future<(List<ModelEvent>, http.Request)> run(
  List<Map<String, Object?>> chunks, {
  int status = 200,
  String? raw,
}) async {
  late http.Request sent;
  final body =
      raw ?? chunks.map((chunk) => 'data: ${jsonEncode(chunk)}\r\n\r\n').join();
  final model = GeminiModel(
    model: 'gemini-3.8-flash',
    apiKey: const Secret('g-key'),
    baseUrl: Uri.parse('https://proxy.example/v1beta'),
    client: MockClient.streaming((request, _) async {
      sent = request as http.Request;
      return http.StreamedResponse(Stream.value(utf8.encode(body)), status);
    }),
  );
  final events = await model
      .generate(const ModelRequest(messages: []))
      .toList();
  return (events, sent);
}

/// A chunk with one candidate made of [parts].
Map<String, Object?> candidate(
  List<Map<String, Object?>> parts, {
  String? finish,
}) => {
  'candidates': [
    {
      'content': {'role': 'model', 'parts': parts},
      'finishReason': ?finish,
    },
  ],
};
