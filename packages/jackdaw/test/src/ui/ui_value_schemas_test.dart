import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  const shout = UiFunctionDefinition(
    name: 'shout',
    description: 'Upper case.',
    args: ObjectSchema(properties: {}),
    returns: UiReturnType.string,
  );
  const remote = UiFunctionDefinition(
    name: 'remote',
    description: 'Runs on the agent.',
    args: ObjectSchema(properties: {}),
    returns: UiReturnType.string,
    callers: UiCaller.agentOnly,
  );

  test('references nested in any schema shape are resolved', () {
    final values = UiValueSchemas(
      const UiCatalog(id: 'c', components: [], functions: [shout]),
    );
    final binding = UiType.dataBinding.ref();
    const path = {'@path': '/x'};
    final shapes = <(Schema, Object?)>[
      (Schema.map(values: binding), {'k': path}),
      (Schema.anyOf([binding]), path),
      (
        UnionSchema(
          discriminator: 'kind',
          variants: {
            'a': ObjectSchema(properties: {'v': binding}),
          },
        ),
        {'kind': 'a', 'v': path},
      ),
    ];
    for (final (shape, valid) in shapes) {
      final resolved = values.resolve(shape, 1);
      expect(resolved.validate(valid), isEmpty);
      expect(resolved.validate({'k': 1, 'v': 1}), isNotEmpty);
      expect(identical(values.resolve(shape, 1), resolved), isTrue);
    }
    expect(values.resolve(const Schema.raw({'type': 'null'}), 1).toJson(), {
      'type': 'null',
    });
    expect(
      values.call('string', 1)!.validate({
        '@call': 'shout',
        'args': <String, Object?>{},
      }),
      isEmpty,
    );
  });

  test('agent-only functions are not offered to the renderer', () {
    final values = UiValueSchemas(
      const UiCatalog(id: 'c', components: [], functions: [remote]),
    );
    expect(values.call('string', 1), isNull);
    expect(
      () => values.type(UiType.functionCall, 1),
      throwsA(isA<StateError>()),
    );
    final action = values.type(UiType.action, 1);
    expect(
      action.validate({
        'event': {'name': 'go'},
      }),
      isEmpty,
    );
    expect(
      action.validate({
        'functionCall': {'@call': 'remote'},
      }),
      isNotEmpty,
    );
  });
}
