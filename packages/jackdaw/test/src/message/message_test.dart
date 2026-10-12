import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('named factories set role and text', () {
    expect(Message.system('s').role, Role.system);
    expect(Message.user('u').role, Role.user);
    expect(Message.assistant('a').text, 'a');
  });

  test('text joins text parts and toolCalls lists calls', () {
    const call = ToolCallPart(id: '1', name: 'weather', arguments: {});
    const message = Message(
      role: Role.assistant,
      parts: [TextPart('a'), call, TextPart('b')],
    );
    expect(message.text, 'ab');
    expect(message.toolCalls, [call]);
  });

  test('tool result defaults to success', () {
    const result = ToolResultPart(callId: '1', name: 'weather', output: 3);
    expect(result.isError, isFalse);
    expect(result.callId, '1');
    expect(result.name, 'weather');
    expect(result.output, 3);
  });

  test('tool call keeps its fields', () {
    const call = ToolCallPart(id: '9', name: 'n', arguments: 'raw');
    expect([call.id, call.name, call.arguments], ['9', 'n', 'raw']);
  });
}
