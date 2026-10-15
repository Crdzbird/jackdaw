import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_bench/src/app/genui_renderer.dart';
import 'package:jackdaw_bench/src/app/jackdaw_renderer.dart';
import 'package:jackdaw_bench/src/app/studio_renderer.dart';
import 'package:jackdaw_bench/src/app/studio_request.dart';
import 'package:jackdaw_bench/src/app/ui_studio.dart';
import 'package:jackdaw_bench/src/app/ui_studio_bar.dart';

const String _ready = 'Describe a form, card, list or screen.';

/// State of [UiStudio]: each request gets a fresh renderer, and earlier
/// requests and answers go with it, so a follow-up changes the screen.
class UiStudioState extends State<UiStudio> {
  final TextEditingController _prompt = TextEditingController(
    text: 'A sign-up form for a coffee shop with name, email and a button',
  );
  final List<Message> _history = [];
  StudioRenderer? _renderer;
  bool _official = false;
  String _status = _ready;
  bool _busy = false;

  @override
  void dispose() {
    _renderer?.dispose();
    _prompt.dispose();
    super.dispose();
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _build() async {
    final renderer = _official
        ? GenuiRenderer(_snack)
        : JackdawRenderer(_snack);
    final request = studioRequest(_history, _prompt.text);
    setState(() {
      _busy = true;
      _status = 'Generating...';
    });
    final watch = Stopwatch()..start();
    Object? reply;
    final problems = await renderer.generate(widget.model, [
      ..._history,
      request,
    ], (answer) => reply = answer);
    if (!mounted) return renderer.dispose();
    _history.addAll([request, Message.assistant(jsonEncode(reply))]);
    if (problems.every((p) => p.warning)) await widget.onBuilt?.call();
    _show(renderer, switch (problems.where((p) => !p.warning).toList()) {
      [] =>
        'Built in ${watch.elapsed.inSeconds} s. Ask for a change, or '
            'start a new screen.',
      [final first, ...] => 'The model left a problem: ${first.message}',
    });
  }

  void _reset([bool? official]) {
    _official = official ?? _official;
    _history.clear();
    _show(null, _ready);
  }

  void _show(StudioRenderer? renderer, String status) {
    final old = _renderer;
    setState(() {
      _busy = false;
      _renderer = renderer;
      _status = status;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiStudioBar(
          prompt: _prompt,
          status: _status,
          busy: _busy,
          official: _official,
          onOfficial: _reset,
          onBuild: _build,
          onReset: _reset,
        ),
        const SizedBox(height: 8),
        Expanded(child: _renderer?.view() ?? const SizedBox.shrink()),
      ],
    ),
  );
}
