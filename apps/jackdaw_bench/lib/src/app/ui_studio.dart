import 'package:flutter/material.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_bench/src/app/ui_studio_state.dart';

/// Generative UI on its own: the model answers a request with a whole
/// screen from the basic catalog, drawn with jackdaw_flutter.
class UiStudio extends StatefulWidget {
  const new({required this.model, this.onBuilt, super.key});

  /// The loaded on-device model.
  final LanguageModel model;

  /// Called after each screen is built without problems.
  final Future<void> Function()? onBuilt;

  @override
  State<UiStudio> createState() => UiStudioState();
}
