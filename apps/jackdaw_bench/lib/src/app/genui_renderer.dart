import 'dart:async';
import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:flutter/material.dart';
import 'package:genui/genui.dart' as genui;
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_bench/src/app/demo_catalog.dart';
import 'package:jackdaw_bench/src/app/genui_catalog.dart';
import 'package:jackdaw_bench/src/app/studio_renderer.dart';

/// Screens drawn by Flutter's official genui package. jackdaw's genui
/// target lowers each screen to A2UI v0.9 and hands it to genui's
/// SurfaceController, which draws it with genui's basic catalog and the
/// demo's Panel.
final class GenuiRenderer implements StudioRenderer {
  /// Creates the renderer; [onAction] describes each action the user
  /// takes on the screen.
  factory(void Function(String action) onAction) = GenuiRenderer._;

  new _(this._onAction) {
    _actions = _controller.onSubmit.listen(_submitted);
    _target = UiTarget.genui(
      demoCatalog,
      send: (messages) {
        for (final message in messages) {
          _controller.handleMessage(a2ui.A2uiMessage.fromJson(message));
        }
      },
    );
  }

  final void Function(String action) _onAction;
  final genui.SurfaceController _controller = genui.SurfaceController(
    catalogs: [demoGenuiCatalog],
  );
  late final StreamSubscription<genui.ChatMessage> _actions;
  late final UiTarget _target;

  @override
  Future<List<UiProblem>> generate(
    LanguageModel model,
    List<Message> messages,
    void Function(Object? reply) onReply,
  ) => generateUi(model, messages, _target, onReply: onReply);

  @override
  Widget view() => switch (_controller.activeSurfaceIds.lastOrNull) {
    final id? => SingleChildScrollView(
      child: genui.Surface(surfaceContext: _controller.contextFor(id)),
    ),
    null => const SizedBox.shrink(),
  };

  void _submitted(genui.ChatMessage message) {
    for (final part in message.parts.whereType<genui.DataPart>()) {
      final interaction = jsonDecode(
        genui.UiInteractionPart.fromDataPart(part).interaction,
      );
      if (interaction case {
        'action': {'name': final name, 'context': final context},
      }) {
        _onAction('$name: $context');
      }
    }
  }

  @override
  void dispose() {
    _actions.cancel().ignore();
    _controller.dispose();
  }
}
