import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_bench/src/app/controls_row.dart';
import 'package:jackdaw_bench/src/app/demo_schema.dart';
import 'package:jackdaw_bench/src/app/describe_stats.dart';
import 'package:jackdaw_bench/src/app/output_view.dart';
import 'package:jackdaw_bench/src/app/playground_view.dart';

/// State of [PlaygroundView]: streams one answer at a time into the screen.
class PlaygroundViewState extends State<PlaygroundView> {
  final TextEditingController _prompt = TextEditingController(
    text: 'What is a jackdaw and where does it live?',
  );
  final StringBuffer _output = StringBuffer();
  StreamSubscription<ModelEvent>? _subscription;
  bool _json = false;
  String _status = 'Model loaded. Ready.';

  @override
  void dispose() {
    _subscription?.cancel().ignore();
    _prompt.dispose();
    super.dispose();
  }

  void _generate() {
    _output.clear();
    final request = ModelRequest(
      messages: [Message.user(_prompt.text)],
      options: const GenerationOptions(maxOutputTokens: 256),
      responseSchema: _json ? demoSchema : null,
    );
    setState(() => _status = 'Generating...');
    _subscription = widget.model
        .generate(request)
        .listen(
          (event) => setState(() => _onEvent(event)),
          onError: (Object error) => setState(() {
            _status = 'Error: $error';
            _subscription = null;
          }),
          onDone: () => setState(() => _subscription = null),
        );
  }

  void _onEvent(ModelEvent event) {
    if (event case TextDelta(:final text)) _output.write(text);
    if (event is FinishEvent) _status = describeStats(widget.model.stats);
  }

  Future<void> _stop() async {
    final subscription = _subscription;
    if (subscription == null) return;
    final watch = Stopwatch()..start();
    await subscription.cancel();
    await widget.model.idle;
    if (!mounted) return;
    setState(() {
      _subscription = null;
      _status =
          'Stopped; native decoding ended in ${watch.elapsedMilliseconds} ms';
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _prompt,
          maxLines: 3,
          minLines: 1,
          decoration: const InputDecoration(
            labelText: 'Prompt',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ControlsRow(
          busy: _subscription != null,
          json: _json,
          onGenerate: _generate,
          onStop: _stop,
          onJson: (value) => setState(() => _json = value),
        ),
        Text(_status, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        OutputView(text: '$_output'),
      ],
    ),
  );
}
