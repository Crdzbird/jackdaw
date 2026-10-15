import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

import 'gallery.dart';

final bool _here = Platform.isMacOS;

Future<void> _pump(WidgetTester tester, ThemeData theme) async {
  tester.view
    ..physicalSize = const Size(480, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ui = UiSurfaceController(basicCatalog)
    ..applyAll(uiTreeMessages(gallery, basicCatalog));
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: UiSurfaceView(controller: ui, surfaceId: 'gallery'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the basic catalog in the light theme', (tester) async {
    await _pump(tester, ThemeData.light());
    await expectLater(
      find.byType(UiSurfaceView),
      matchesGoldenFile('goldens/basic_catalog_light.png'),
    );
  }, skip: !_here);

  testWidgets('the basic catalog in the dark theme', (tester) async {
    await _pump(tester, ThemeData.dark());
    await expectLater(
      find.byType(UiSurfaceView),
      matchesGoldenFile('goldens/basic_catalog_dark.png'),
    );
  }, skip: !_here);
}
