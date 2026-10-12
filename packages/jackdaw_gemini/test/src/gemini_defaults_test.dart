import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_gemini/jackdaw_gemini.dart';
import 'package:jackdaw_gemini/src/gemini_request_encoder.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('maps API errors', () async {
    await expectLater(
      run(
        const [],
        status: 400,
        raw: '{"error":{"code":400,"message":"bad schema"}}',
      ),
      throwsA(
        isA<ProviderException>().having((e) => e.message, 'm', 'bad schema'),
      ),
    );
  });

  test('omits optional sections', () {
    expect(encodeGenerateRequest(const ModelRequest(messages: [])).keys, [
      'contents',
    ]);
  });

  test('uses the public endpoint by default', () async {
    late Uri url;
    final model = GeminiModel(
      model: 'gemini-3.8-flash',
      apiKey: const Secret('k'),
      client: MockClient.streaming((request, _) async {
        url = request.url;
        return http.StreamedResponse(Stream.value(utf8.encode('')), 200);
      }),
    );
    await model.generate(const ModelRequest(messages: [])).drain<void>();
    expect(url.host, 'generativelanguage.googleapis.com');
    expect(url.path, '/v1beta/models/gemini-3.8-flash:streamGenerateContent');
    expect(model.id, 'gemini/gemini-3.8-flash');
    expect(model.headers, isEmpty);
  });

  test('generation config carries sampling and the schema', () {
    final body = encodeGenerateRequest(
      const ModelRequest(
        messages: [],
        options: GenerationOptions(temperature: 0.2, maxOutputTokens: 50),
        responseSchema: Schema.boolean(),
      ),
    );
    expect(body['generationConfig'], {
      'temperature': 0.2,
      'maxOutputTokens': 50,
      'responseMimeType': 'application/json',
      'responseJsonSchema': {'type': 'boolean'},
    });
  });
}
