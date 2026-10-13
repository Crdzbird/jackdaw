import 'package:flutter/material.dart';
import 'package:jackdaw_flutter/src/controller/chat_controller.dart';
import 'package:jackdaw_flutter/src/controller/chat_listenables.dart';
import 'package:jackdaw_flutter/src/controller/chat_status.dart';

part 'chat_composer_state.dart';

/// A text field that sends to the chat, with a stop button while the agent
/// is answering.
final class ChatComposer extends StatefulWidget {
  /// Sends to [controller]; [hint] is shown in the empty field.
  const factory({required ChatController controller, String hint, Key? key}) =
      ChatComposer._;

  const new _({required this.controller, this.hint = 'Message', super.key});

  /// The chat that receives messages.
  final ChatController controller;

  /// Placeholder text of the empty field.
  final String hint;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}
