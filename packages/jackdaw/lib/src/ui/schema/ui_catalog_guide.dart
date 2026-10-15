import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/ui/catalog/ui_catalog.dart';
import 'package:jackdaw/src/ui/catalog/ui_function_definition.dart';
import 'package:jackdaw/src/ui/schema/ui_format.dart';
import 'package:jackdaw/src/ui/schema/ui_guide_texts.dart';

/// A short description of how to write UI with [catalog] in [format], for
/// the prompt of a model that cannot read the full schema.
///
/// It lists each component with its props, marking required ones with a
/// star and giving enum values, and each function with its arguments and
/// what it returns, then shows [example]: by default one for the basic
/// catalog in [format]; pass another for other catalogs, or an empty
/// string for none.
String uiCatalogGuide(
  UiCatalog catalog, {
  UiFormat format = UiFormat.messages,
  String? example,
}) => [
  if (format == UiFormat.tree) uiTreeIntro,
  if (format == UiFormat.messages) uiMessagesIntro,
  ?catalog.instructions,
  'Components:',
  for (final c in catalog.components)
    '- ${c.name}(${_props(c.props)}): ${c.description}',
  if (catalog.functions.isNotEmpty) 'Functions:',
  for (final f in catalog.functions) _function(f),
  if (example ?? uiGuideExample(format) case final text when text.isNotEmpty)
    text,
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
