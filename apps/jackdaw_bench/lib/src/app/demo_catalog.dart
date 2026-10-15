import 'package:flutter/material.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

const Map<String, MaterialColor> _colors = {
  'red': Colors.red,
  'orange': Colors.orange,
  'yellow': Colors.yellow,
  'green': Colors.green,
  'teal': Colors.teal,
  'blue': Colors.blue,
  'purple': Colors.purple,
  'pink': Colors.pink,
  'brown': Colors.brown,
  'gray': Colors.grey,
};

/// The A2UI basic catalog plus a Panel, a colored background, to show
/// how an app adds its own components. The v1.0 basic catalog has no
/// colors of its own.
final UiCatalog demoCatalog = UiCatalog(
  id: 'dev.crdzbird.jackdaw_bench/demo',
  title: 'jackdaw demo catalog',
  instructions: basicCatalog.instructions,
  components: [
    ...basicCatalog.components,
    UiComponentDefinition(
      name: 'Panel',
      description:
          'A colored background around one child. Wrap the whole screen '
          'in it when the user asks for a background color.',
      props: ObjectSchema(
        properties: {
          'color': Schema.string(
            enumValues: [..._colors.keys],
            description: 'The background color.',
          ),
          'child': UiType.child.ref(description: 'The content.'),
        },
        required: ['color', 'child'],
      ),
    ),
  ],
  functions: basicCatalog.functions,
);

/// Draws the components of [demoCatalog]: the basic ones and the Panel.
final Map<String, UiWidgetBuilder> demoUiBuilders = {
  ...basicUiBuilders,
  'Panel': (node) => ColoredBox(
    color: _colors[node.text('color')]?.shade200 ?? Colors.transparent,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: node.child('child'),
    ),
  ),
};
