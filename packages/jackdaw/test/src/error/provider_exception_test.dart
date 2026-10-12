import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  ProviderException error(int? status) =>
      ProviderException(provider: 'p', message: 'm', statusCode: status);

  test('retryable for rate limits and server errors only', () {
    expect(error(429).isRetryable, isTrue);
    expect(error(503).isRetryable, isTrue);
    expect(error(400).isRetryable, isFalse);
    expect(error(null).isRetryable, isFalse);
  });

  test('describes itself', () {
    const e = ProviderException(
      provider: 'openai',
      message: 'slow down',
      statusCode: 429,
      retryAfter: Duration(seconds: 2),
    );
    expect('$e', 'ProviderException(openai, 429): slow down');
    expect(e.retryAfter, const Duration(seconds: 2));
  });

  test('parses Retry-After seconds', () {
    expect(parseRetryAfter(null), isNull);
    expect(parseRetryAfter('5'), const Duration(seconds: 5));
    expect(parseRetryAfter(' 7 '), const Duration(seconds: 7));
    expect(parseRetryAfter('-1'), isNull);
    expect(parseRetryAfter('Wed, 21 Oct 2026 07:28:00 GMT'), isNull);
  });
}
