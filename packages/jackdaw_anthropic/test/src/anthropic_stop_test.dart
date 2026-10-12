import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('maps every stop reason', () async {
    const reasons = {
      'max_tokens': FinishReason.length,
      'refusal': FinishReason.contentFilter,
      'pause_turn': FinishReason.other,
    };
    for (final MapEntry(:key, :value) in reasons.entries) {
      final events = await run([messageDelta(key, 1)]);
      expect((events.single as FinishEvent).reason, value);
    }
  });

  test('unknown stream errors carry no status code', () async {
    await expectLater(
      run([
        {
          'type': 'error',
          'error': {'type': 'mystery_error'},
        },
      ]),
      throwsA(
        isA<ProviderException>().having((e) => e.statusCode, 's', isNull),
      ),
    );
  });
}
