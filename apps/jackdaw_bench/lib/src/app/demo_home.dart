import 'package:flutter/material.dart';
import 'package:jackdaw_bench/src/app/demo_home_state.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

/// The demo once the model is loaded: an agent chat and a raw playground.
class DemoHome extends StatefulWidget {
  const new({required this.model, required this.sessions, super.key});

  /// The loaded on-device model.
  final LocalModel model;

  /// Folder for session journals.
  final String sessions;

  @override
  State<DemoHome> createState() => DemoHomeState();
}
