import 'package:flutter/material.dart';
import 'package:jackdaw_bench/src/app/chat_view.dart';
import 'package:jackdaw_bench/src/app/model_loader.dart';
import 'package:jackdaw_bench/src/app/model_path.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

/// State of [ModelLoader]. The model lives as long as the app.
class ModelLoaderState extends State<ModelLoader> {
  late final Future<LocalModel> _model = LocalModel.open(modelPath);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('jackdaw on device')),
    body: FutureBuilder<LocalModel>(
      future: _model,
      builder: (context, snapshot) {
        if (snapshot.error case final error?) {
          return Center(child: Text('Could not load the model: $error'));
        }
        if (snapshot.data case final model?) return ChatView(model: model);
        return const Center(child: Text('Loading Qwen2.5-1.5B...'));
      },
    ),
  );
}
