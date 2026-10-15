import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_bench/src/app/demo_catalog.dart';
import 'package:jackdaw_bench/src/app/demo_home.dart';
import 'package:jackdaw_bench/src/app/model_loader.dart';
import 'package:jackdaw_bench/src/app/model_path.dart';
import 'package:jackdaw_bench/src/app/model_status.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

/// State of [ModelLoader]. Downloads the default model the first time,
/// unless a model file is given, then keeps it for the life of the app.
class ModelLoaderState extends State<ModelLoader> {
  late Future<LocalModel> _model = _load();
  ModelDownloadProgress? _progress;

  String get _folder =>
      modelPath.isEmpty ? dataFolder : File(modelPath).parent.path;

  Future<LocalModel> _load() async => await _prepare(await _open());

  Future<LocalModel> _prepare(LocalModel model) async {
    gbnfGrammar(demoCatalog.schemas.tree);
    await model.loadState(uiStateFile('$_folder/sessions'));
    return model;
  }

  Future<LocalModel> _open() async {
    if (modelPath.isNotEmpty) return await LocalModel.open(modelPath);
    const qwen = ModelFile.qwen25Instruct;
    final model = await LocalModel.download(
      Directory(dataFolder),
      model: modelUrl.isEmpty ? qwen : qwen.from(modelUrl),
      onProgress: (progress) {
        if (mounted) setState(() => _progress = progress);
      },
    );
    if (mounted) setState(() => _progress = null);
    return model;
  }

  void _retry() => setState(() {
    _progress = null;
    _model = _load();
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<LocalModel>(
    future: _model,
    builder: (context, snapshot) {
      if (snapshot.data case final model?) {
        return DemoHome(model: model, sessions: '$_folder/sessions');
      }
      return Scaffold(
        appBar: AppBar(title: const Text('jackdaw on device')),
        body: Center(
          child: ModelStatus(
            progress: _progress,
            error: snapshot.error,
            onRetry: _retry,
          ),
        ),
      );
    },
  );
}
