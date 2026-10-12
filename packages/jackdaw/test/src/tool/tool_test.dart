import 'dart:async';

import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

const schema = ObjectSchema(
  properties: {'city': Schema.string()},
  required: ['city'],
);

Tool<String> weather(FutureOr<Object?> Function(String city) run) =>
    Tool<String>(
      name: 'weather',
      description: 'Current weather',
      input: schema,
      decode: (json) => json['city']! as String,
      run: run,
      timeout: const Duration(milliseconds: 20),
    );

ToolCallPart call(Object? arguments) =>
    ToolCallPart(id: 'c1', name: 'weather', arguments: arguments);

void main() {
  test('exposes its spec', () {
    final spec = weather((city) => city).spec;
    expect([spec.name, spec.description], ['weather', 'Current weather']);
    expect(spec.input, same(schema));
  });

  test('decodes validated input and returns output', () async {
    final result = await weather((city) => '$city: sunny')
        .invoke(call({'city': 'Lima'}));
    expect(result.isError, isFalse);
    expect(result.callId, 'c1');
    expect(result.output, 'Lima: sunny');
  });

  test('rejects invalid arguments without running', () async {
    var ran = false;
    final tool = weather((city) => ran = true);
    final missing = await tool.invoke(call(<String, Object?>{}));
    final raw = await tool.invoke(call('{not json'));
    expect(ran, isFalse);
    expect(missing.isError, isTrue);
    expect(missing.output, {'error': r'invalid arguments: $.city is required'});
    expect(raw.output, {'error': r'invalid arguments: $ expected an object'});
  });

  test('turns thrown errors into error results', () async {
    final result = await weather((_) => throw StateError('down'))
        .invoke(call({'city': 'Lima'}));
    expect(result.isError, isTrue);
    expect(result.output, {'error': 'Bad state: down'});
  });

  test('times out slow handlers', () async {
    final result = await weather((_) => Completer<Object?>().future)
        .invoke(call({'city': 'Lima'}));
    expect(result.output, {'error': 'timed out after 20 ms'});
  });

  test('default timeout is thirty seconds', () {
    final tool = Tool<Object?>(
      name: 'n',
      description: 'd',
      input: schema,
      decode: (json) => json,
      run: (input) => input,
    );
    expect(tool.timeout, const Duration(seconds: 30));
  });
}
