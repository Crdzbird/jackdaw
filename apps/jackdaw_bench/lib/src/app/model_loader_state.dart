import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jackdaw_bench/src/app/demo_home.dart';
import 'package:jackdaw_bench/src/app/model_loader.dart';
import 'package:jackdaw_bench/src/app/model_path.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

/// State of [ModelLoader]. The model lives as long as the app.
class ModelLoaderState extends State<ModelLoader> {
  late final Future<LocalModel> _model = LocalModel.open(modelPath);

  @override
  Widget build(BuildContext context) => FutureBuilder<LocalModel>(
    future: _model,
    builder: (context, snapshot) {
      if (snapshot.data case final model?) {
        final sessions = '${File(modelPath).parent.path}/sessions';
        return DemoHome(model: model, sessions: sessions);
      }
      return Scaffold(
        appBar: AppBar(title: const Text('jackdaw on device')),
        body: Center(
          child: Text(
            snapshot.error == null
                ? 'Loading the model from $modelPath...'
                : 'Could not load the model at $modelPath: ${snapshot.error}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    },
  );
}
