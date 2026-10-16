import 'package:flutter/material.dart';

/// The screen the writes of both sides are measured in: [first] and
/// [second] scrolling one above the other under a spinner, so the sides
/// can take turns frame by frame on a core at the same clock.
Widget comparePair(Widget first, Widget second) => MaterialApp(
  home: Scaffold(
    body: Column(
      children: [
        const CircularProgressIndicator(),
        Expanded(child: SingleChildScrollView(child: first)),
        Expanded(child: SingleChildScrollView(child: second)),
      ],
    ),
  ),
);
