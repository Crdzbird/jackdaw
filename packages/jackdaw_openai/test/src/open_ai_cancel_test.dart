import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_openai/jackdaw_openai.dart';
import 'package:test/test.dart';

void main() {
  test('cancelling the stream aborts the request', () async {
    final body = StreamController<List<int>>();
    final trigger = Completer<Future<void>>();
    final client = MockClient.streaming((request, _) async {
      trigger.complete((request as http.Abortable).abortTrigger);
      return http.StreamedResponse(body.stream, 200);
    });
    final model = OpenAiModel(model: 'm', client: client);
    body.add(utf8.encode('data: {"choices":[{"delta":{"content":"a"}}]}\n\n'));
    final first = await model.generate(const ModelRequest(messages: [])).first;
    await (await trigger.future).timeout(const Duration(seconds: 1));
    expect((first as TextDelta).text, 'a');
    await body.close();
  });
}
