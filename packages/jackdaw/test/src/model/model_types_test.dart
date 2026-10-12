import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('usage adds known counts and keeps unknown as null', () {
    const a = Usage(inputTokens: 2);
    const b = Usage(inputTokens: 3, outputTokens: 4);
    final sum = a + b;
    expect(sum.inputTokens, 5);
    expect(sum.outputTokens, 4);
    expect((b + a).outputTokens, 4);
    expect((const Usage() + const Usage()).inputTokens, isNull);
  });

  test('request and options defaults', () {
    const request = ModelRequest(messages: []);
    expect(request.tools, isEmpty);
    expect(request.options.temperature, isNull);
    expect(request.options.maxOutputTokens, isNull);
    const options = GenerationOptions(temperature: 0.2, maxOutputTokens: 9);
    expect([options.temperature, options.maxOutputTokens], [0.2, 9]);
  });

  test('events carry their payloads', () {
    const call = ToolCallPart(id: '1', name: 'n', arguments: null);
    expect(const TextDelta('x').text, 'x');
    expect(const ToolCallEvent(call).call, same(call));
    const finish = FinishEvent(reason: FinishReason.length);
    expect(finish.reason, FinishReason.length);
    expect(finish.usage.outputTokens, isNull);
  });
}
