import 'package:flutter/material.dart';

/// [child] 200 wide in a Material app with [theme], read in [direction].
Widget ruleFrame(
  Widget child, {
  required bool material3,
  DividerThemeData? theme,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  theme: ThemeData(useMaterial3: material3, dividerTheme: theme),
  home: Directionality(
    textDirection: direction,
    child: Scaffold(
      body: Column(children: [SizedBox(width: 200, child: child)]),
    ),
  ),
);
