import 'package:flutter/material.dart';
import 'package:jackdaw_bench/src/app/chat_view_state.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

/// Prompt box, streamed answer, stop button and JSON mode switch.
class ChatView extends StatefulWidget {
  const new({required this.model, super.key});

  final LocalModel model;

  @override
  State<ChatView> createState() => ChatViewState();
}
