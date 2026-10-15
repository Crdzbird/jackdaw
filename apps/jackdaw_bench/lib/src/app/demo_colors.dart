import 'package:flutter/material.dart';

/// The background colors the demo's Panel component offers, by name.
const Map<String, MaterialColor> demoColors = {
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

/// The light shade of the color named [name] that a Panel draws, so text
/// stays readable on it.
Color demoColor(String? name) =>
    demoColors[name]?.shade200 ?? Colors.transparent;
