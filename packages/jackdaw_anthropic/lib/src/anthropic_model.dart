import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_anthropic/src/anthropic_request_encoder.dart';
import 'package:jackdaw_anthropic/src/anthropic_stream_decoder.dart';

/// A [LanguageModel] backed by the Anthropic Messages API.
///
/// Streams text, tool calls and thinking blocks. Thinking blocks are kept
/// in the transcript and sent back unchanged on later turns, which Claude
/// requires when tools are used. Cancelling the stream aborts the request.
final class AnthropicModel implements LanguageModel {
  /// Creates a model that calls [model], such as `claude-opus-5-5`.
  const factory({
    required String model,
    required Secret apiKey,
    Uri? baseUrl,
    http.Client? client,
    Map<String, String> headers,
    int defaultMaxTokens,
  }) = AnthropicModel._;

  const new _({
    required this.model,
    required this._apiKey,
    this.baseUrl,
    this._client,
    this.headers = const {},
    this.defaultMaxTokens = 64000,
  });

  /// Model name sent to the API.
  final String model;

  /// API root; defaults to `https://api.anthropic.com/v1/`.
  final Uri? baseUrl;

  /// Extra headers, such as `anthropic-beta`.
  final Map<String, String> headers;

  /// `max_tokens` used when the request does not set one.
  final int defaultMaxTokens;

  final Secret _apiKey;
  final http.Client? _client;

  @override
  String get id => 'anthropic/$model';

  @override
  Stream<ModelEvent> generate(ModelRequest request) {
    final decoder = AnthropicStreamDecoder();
    final root = baseUrl ?? Uri.parse('https://api.anthropic.com/v1/');
    final base = root.path.endsWith('/')
        ? root
        : root.replace(path: '${root.path}/');
    final body = HttpTransport(provider: 'anthropic', client: _client).postJson(
      base.resolve('messages'),
      headers: {
        ...headers,
        'x-api-key': _apiKey.reveal(),
        'anthropic-version': '2023-06-01',
        'accept': 'text/event-stream',
      },
      body: encodeMessagesRequest(
        model,
        request,
        defaultMaxTokens: defaultMaxTokens,
      ),
    );
    return body
        .transform(const SseDecoder())
        .expand((event) => decoder.accept(jsonDecode(event.data)))
        .transform(appendOnDone(decoder.finish));
  }
}
