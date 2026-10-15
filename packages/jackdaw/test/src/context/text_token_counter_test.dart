import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('each message is tokenized once', () {
    var calls = 0;
    final counter = TokenCounter.fromText((text) {
      calls++;
      return text.length;
    }, overhead: 1);
    final hello = Message.user('hello');
    final there = Message.assistant('there');
    expect(counter.count(hello), 6);
    expect(counter.count(hello), 6);
    expect(counter.count(there), 6);
    expect(calls, 2);
  });
}
