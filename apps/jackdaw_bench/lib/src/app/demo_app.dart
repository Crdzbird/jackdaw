import 'package:flutter/material.dart';
import 'package:jackdaw_bench/src/app/model_loader.dart';

/// On-device demo of jackdaw's native core.
class DemoApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'jackdaw',
    theme: ThemeData(colorSchemeSeed: Colors.blueGrey, useMaterial3: true),
    home: const ModelLoader(),
  );
}
