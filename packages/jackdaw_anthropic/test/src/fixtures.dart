import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_anthropic/jackdaw_anthropic.dart';

/// Encodes [events] the way the Messages API streams them.
Stream<List<int>> sse(List<Map<String, Object?>> events) =>
    Stream.fromIterable([
      for (final event in events)
        utf8.encode('event: ${event['type']}\ndata: ${jsonEncode(event)}\n\n'),
    ]);

/// A client answering every request with [body].
MockClient replying(
  Stream<List<int>> body, {
  int status = 200,
  void Function(http.Request request)? onRequest,
}) => MockClient.streaming((request, _) async {
  onRequest?.call(request as http.Request);
  return http.StreamedResponse(body, status);
});

Map<String, Object?> start(int index, Map<String, Object?> block) => {
  'type': 'content_block_start',
  'index': index,
  'content_block': block,
};

Map<String, Object?> delta(int index, Map<String, Object?> delta) => {
  'type': 'content_block_delta',
  'index': index,
  'delta': delta,
};

Map<String, Object?> stop(int index) => {
  'type': 'content_block_stop',
  'index': index,
};

Map<String, Object?> messageDelta(String reason, int output) => {
  'type': 'message_delta',
  'delta': {'stop_reason': reason, 'stop_sequence': null},
  'usage': {'output_tokens': output},
};

const Map<String, Object?> messageStart = {
  'type': 'message_start',
  'message': {
    'id': 'msg_1',
    'usage': {
      'input_tokens': 20,
      'cache_read_input_tokens': 5,
      'output_tokens': 1,
    },
  },
};

/// Streams [events] through an [AnthropicModel] and collects the result.
Future<List<ModelEvent>> run(List<Map<String, Object?>> events) =>
    AnthropicModel(
      model: 'm',
      apiKey: const Secret('k'),
      client: replying(sse(events)),
    ).generate(const ModelRequest(messages: [])).toList();
