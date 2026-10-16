import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jaspr/client.dart';
import 'package:jaspr/dom.dart';

/// The smallest page that draws the bench screen with genui_jaspr, from
/// the same messages already in A2UI v0.9, to measure what the library
/// adds to a page's script.
void main() {
  final catalog = BasicJasprCatalog();
  final processor = MessageProcessor<JasprComponent>(catalogs: [catalog])
    ..processMessages([
      for (final message in benchMessages) A2uiMessage.fromJson(message),
    ]);
  runApp(
    div([
      Style(styles: catalog.styles),
      Surface(surface: processor.groupModel.getSurface('bench')!),
    ]),
  );
}

/// The bench screen lowered to A2UI v0.9: a column of texts, fields,
/// checkboxes, sliders and dividers, written out so this page does not
/// carry jackdaw.
final List<Map<String, Object?>> benchMessages = [
  {
    'version': 'v0.9',
    'createSurface': {
      'surfaceId': 'bench',
      'catalogId': BasicJasprCatalog.catalogId,
    },
  },
  {
    'version': 'v0.9',
    'updateComponents': {
      'surfaceId': 'bench',
      'components': [
        {
          'id': 'root',
          'component': 'Column',
          'children': [for (var i = 0; i < 39; i++) 'c$i'],
        },
        for (var i = 0; i < 39; i++)
          switch (i % 5) {
            0 => {
              'id': 'c$i',
              'component': 'Text',
              'text': {'path': '/t$i'},
            },
            1 => {
              'id': 'c$i',
              'component': 'TextField',
              'label': 'Field $i',
              'value': {'path': '/t$i'},
            },
            2 => {
              'id': 'c$i',
              'component': 'CheckBox',
              'label': 'Box $i',
              'value': {'path': '/b$i'},
            },
            3 => {
              'id': 'c$i',
              'component': 'Slider',
              'max': 10,
              'value': {'path': '/n$i'},
            },
            _ => {'id': 'c$i', 'component': 'Divider'},
          },
      ],
    },
  },
  {
    'version': 'v0.9',
    'updateDataModel': {
      'surfaceId': 'bench',
      'path': '/',
      'value': {for (var i = 0; i < 40; i++) 't$i': 'Value $i'},
    },
  },
];
