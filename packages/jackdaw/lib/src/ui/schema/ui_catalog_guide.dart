import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/catalog/ui_function_definition.dart';

/// A short description of how to write A2UI v1.0 messages with [catalog],
/// for the prompt of a model that cannot read the full schema.
///
/// It lists each component with its props, marking required ones with a
/// star and giving enum values, and each function with its arguments and
/// what it returns, then shows [example], which suits the basic catalog;
/// pass another for other catalogs, or `null` for none.
String uiCatalogGuide(UiCatalog catalog, {String? example = uiGuideExample}) =>
    [
      _intro,
      ?catalog.instructions,
      'Components:',
      for (final c in catalog.components)
        '- ${c.name}(${_props(c.props)}): ${c.description}',
      if (catalog.functions.isNotEmpty) 'Functions:',
      for (final f in catalog.functions) _function(f),
      ?example,
    ].join('\n');

String _function(UiFunctionDefinition f) =>
    '- ${f.name}(${_props(f.args)}) returns ${f.returns.wire}: '
    '${f.description}';

String _props(ObjectSchema schema) => [
  for (final MapEntry(:key, :value) in schema.properties.entries)
    [
      key,
      if (schema.required.contains(key)) '*',
      if (value case StringSchema(enumValues: final values?))
        ' ${values.join('|')}',
    ].join(),
].join(', ');

/// A small screen in the basic catalog, shown to the model as an example.
const String uiGuideExample =
    'Example, a name field and a button that sends it:\n'
    '[{"version": "v1.0", "createSurface": {"surfaceId": "greet", '
    '"components": [ '
    '{"id": "root", "component": "Column", "children": ["name", "go"]}, '
    '{"id": "name", "component": "TextField", "label": "Name", '
    '"value": {"@path": "/name"}}, '
    '{"id": "go", "component": "Button", "child": "goText", '
    '"action": {"event": {"name": "greet", '
    '"context": {"name": {"@path": "/name"}}}}}, '
    '{"id": "goText", "component": "Text", "text": "Say hi"}], '
    '"dataModel": {"name": ""}}}]';

const String _intro =
    'Write A2UI v1.0 messages as a JSON list. A screen is usually one '
    'createSurface message with every component and the initial '
    'dataModel. Each component has an id and a component name; the top '
    'one has the id root and children are listed by id. A value is a '
    'literal, {"@path": "/a/b"} to read the data model, or {"@call": '
    '"name", "args": {...}} to call a function.';
