import 'package:jackdaw/src/schema/schema.dart';

/// The A2UI v1.0 common types a catalog refers to from its props and
/// function arguments.
///
/// A catalog writes a reference as `{"$ref": "common_types.json#/$defs/T"}`.
/// The schemas that validate and constrain such a value depend on the
/// functions of the catalog, so they are built per catalog.
enum UiType {
  /// A string, a data binding or a call returning a string.
  dynamicString('DynamicString'),

  /// A number, a data binding or a call returning a number.
  dynamicNumber('DynamicNumber'),

  /// A boolean, a data binding or a call returning a boolean.
  dynamicBoolean('DynamicBoolean'),

  /// A list of strings, a data binding or a call returning one.
  dynamicStringList('DynamicStringList'),

  /// Any literal, a data binding or a call.
  dynamicValue('DynamicValue'),

  /// A reference to a data model path, written `{"@path": "/a/b"}`.
  dataBinding('DataBinding'),

  /// The id of one child component.
  child('Child'),

  /// A list of child ids, or a template repeated over a data model list.
  childList('ChildList'),

  /// An event sent to the agent, or a function called on the renderer.
  action('Action'),

  /// A call to a catalog function, written `{"@call": "name", "args": {}}`.
  functionCall('FunctionCall'),

  /// A validation rule with a condition and an optional message.
  checkRule('CheckRule');

  new(this.name);

  /// The name of the type in `common_types.json`.
  final String name;

  /// The reference to this type, with an optional [description].
  Schema ref({String? description}) => RawSchema({
    r'$ref': 'common_types.json#/\$defs/$name',
    'description': ?description,
  });

  /// The type [schema] refers to, or `null` when it is not a reference.
  static UiType? of(Schema schema) => switch (schema) {
    RawSchema(json: {r'$ref': final String ref}) => _byRef.putIfAbsent(
      ref,
      () => values.where((t) => ref.endsWith('/${t.name}')).firstOrNull,
    ),
    _ => null,
  };

  static final Map<String, UiType?> _byRef = {};
}
