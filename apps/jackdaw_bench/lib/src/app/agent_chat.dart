import 'package:flutter/material.dart';
import 'package:jackdaw_bench/src/app/agent_chat_state.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

/// A multi-turn chat with an agent over the on-device model, using the
/// jackdaw_flutter widgets; it can also show the forms and cards the agent
/// builds. The session is journalled to [sessions], so it survives an app
/// restart.
class AgentChat extends StatefulWidget {
  const new({required this.model, required this.sessions, super.key});

  /// The loaded on-device model.
  final LocalModel model;

  /// Folder for session journals.
  final String sessions;

  @override
  State<AgentChat> createState() => AgentChatState();
}
