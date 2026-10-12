import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('secret never prints its value', () {
    const secret = Secret('sk-canary');
    expect('$secret', 'Secret(redacted)');
    expect('$secret', isNot(contains('canary')));
    expect(secret.reveal(), 'sk-canary');
  });
}
