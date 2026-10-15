import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

/// Shows a surface `s` made of [components], with [data] as its data
/// model, and returns its controller.
Future<UiSurfaceController> showSurface(
  WidgetTester tester,
  List<Map<String, Object?>> components, {
  Map<String, Object?> data = const {},
  UiHost host = const UiHost(),
  void Function(UiAction action)? onAction,
}) async {
  final controller = UiSurfaceController(
    basicCatalog,
    host: host,
    onAction: onAction,
  );
  controller.surfaces.applyAll([
    {
      'version': 'v1.0',
      'createSurface': {
        'surfaceId': 's',
        'components': components,
        'dataModel': data,
      },
    },
  ]);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: UiSurfaceView(controller: controller, surfaceId: 's'),
        ),
      ),
    ),
  );
  return controller;
}

/// The value at [pointer] in the data of the surface `s`.
Object? dataAt(UiSurfaceController controller, String pointer) =>
    controller.surfaces.surfaces['s']!.data.read(pointer);

/// A component [id] of [type] with the props [p].
Map<String, Object?> c(
  String id,
  String type, [
  Map<String, Object?> p = const {},
]) => {'id': id, 'component': type, ...p};
