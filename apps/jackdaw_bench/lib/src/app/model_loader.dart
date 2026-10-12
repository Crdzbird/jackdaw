import 'package:flutter/material.dart';
import 'package:jackdaw_bench/src/app/model_loader_state.dart';

/// Loads the model off the UI isolate, then shows the chat view.
class ModelLoader extends StatefulWidget {
  const new({super.key});

  @override
  State<ModelLoader> createState() => ModelLoaderState();
}
