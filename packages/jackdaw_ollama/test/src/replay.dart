import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_ollama/jackdaw_ollama.dart';

/// Streams [body] through an [OllamaModel], returning events and the
/// request that was sent.
Future<(List<ModelEvent>, http.Request)> replay(
  String body, {
  int status = 200,
  ModelRequest request = const ModelRequest(messages: []),
}) async {
  late http.Request sent;
  final client = MockClient.streaming((r, _) async {
    sent = r as http.Request;
    return http.StreamedResponse(Stream.value(utf8.encode(body)), status);
  });
  final model = OllamaModel(
    model: 'qwen2.5:3b-instruct',
    baseUrl: Uri.parse('http://box:11434'),
    client: client,
    numCtx: 4096,
    topK: 40,
    keepAlive: '5m',
  );
  final events = await model.generate(request).toList();
  return (events, sent);
}
