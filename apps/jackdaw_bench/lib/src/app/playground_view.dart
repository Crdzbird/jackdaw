import 'package:flutter/material.dart';
import 'package:jackdaw_bench/src/app/playground_view_state.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

/// Raw generation: prompt box, streamed answer, stop button, JSON mode
/// switch and native timings.
class PlaygroundView extends StatefulWidget {
  const new({required this.model, super.key});

  final LocalModel model;

  @override
  State<PlaygroundView> createState() => PlaygroundViewState();
}
