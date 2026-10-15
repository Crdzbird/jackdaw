import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

void main() {
  test('the basic catalog has every A2UI v1.0 component and function', () {
    expect(
      basicCatalog.components.map((c) => c.name).join(' '),
      'Text Image Icon Video AudioPlayer Row Column List Card Tabs Modal '
      'Divider Button TextField CheckBox ChoicePicker Slider DateTimeInput',
    );
    expect(
      basicCatalog.functions.map((f) => f.name).join(' '),
      'required regex length numeric email formatString formatNumber '
      'formatCurrency formatDate pluralize openUrl and or not',
    );
    expect(basicCatalog.instructions, contains('formatString'));
  });

  test('lookups find components and functions by name', () {
    expect(basicCatalog.component('Card')!.props.required, ['child']);
    expect(basicCatalog.component('Missing'), isNull);
    expect(basicCatalog.function('not')!.returns, UiReturnType.boolean);
    expect(basicCatalog.function('missing'), isNull);
  });

  test('components serialize as catalog entries with common type refs', () {
    final json = basicCatalog.component('CheckBox')!.toJson();
    expect(json['required'], ['component', 'label', 'value']);
    final properties = json['properties']! as Map<String, Object?>;
    expect(properties['component'], {'const': 'CheckBox'});
    expect(properties['value'], {
      r'$ref': r'common_types.json#/$defs/DynamicBoolean',
      'description': 'Whether it is checked, usually a binding.',
    });
    const placed = UiComponentDefinition(
      name: 'Toolbar',
      description: 'A toolbar.',
      props: ObjectSchema(properties: {}),
      allowedParents: ['Surface'],
      allowedChildren: ['Button'],
    );
    expect(placed.toJson()['allowedParents'], ['Surface']);
    expect(placed.toJson()['allowedChildren'], ['Button']);
  });

  test('functions serialize with their return type and callers', () {
    final open = basicCatalog.function('openUrl')!.toJson();
    expect(open['returnType'], 'void');
    expect(open['requiresUserActivation'], isTrue);
    expect(open['required'], ['@call', 'args']);
    expect(open.containsKey('allowedCallers'), isFalse);
    final shared = const UiFunctionDefinition(
      name: 'now',
      description: 'The time.',
      args: ObjectSchema(properties: {}),
      returns: UiReturnType.string,
      callers: UiCaller.rendererOrAgent,
    ).toJson();
    expect(shared['allowedCallers'], 'rendererOrAgent');
    expect(shared.containsKey('requiresUserActivation'), isFalse);
  });

  test('the catalog serializes as a v1.0 catalog definition', () {
    final json = basicCatalog.toJson();
    expect(json['catalogId'], basicCatalog.id);
    expect(json['protocolVersion'], '1.0');
    expect((json['components']! as Map).length, 18);
    expect((json['functions']! as Map).length, 14);
    const bare = UiCatalog(id: 'x', components: []);
    expect(bare.toJson().keys, [
      'catalogId',
      'protocolVersion',
      'components',
      'functions',
    ]);
  });

  test('common type references are recognized', () {
    expect(UiType.of(UiType.childList.ref()), UiType.childList);
    expect(UiType.of(const Schema.raw({r'$ref': '#/x'})), isNull);
    expect(UiType.of(const Schema.string()), isNull);
    expect(UiType.dataBinding.ref().toJson(), {
      r'$ref': r'common_types.json#/$defs/DataBinding',
    });
  });
}
