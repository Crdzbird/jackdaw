import 'package:flutter/material.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_bench/src/app/ui_studio.dart';
import 'package:jackdaw_flutter/jackdaw_flutter.dart';

/// State of [UiStudio]: one request at a time, each drawn on a fresh
/// controller so the last screen is the one shown.
class UiStudioState extends State<UiStudio> {
  final TextEditingController _prompt = TextEditingController(
    text: 'A sign-up form for a coffee shop with name, email and a button',
  );
  UiSurfaceController? _ui;
  String _status = 'Describe a form, card, list or screen.';
  bool _busy = false;

  @override
  void dispose() {
    _ui?.dispose();
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final ui = UiSurfaceController(
      basicCatalog,
      host: UiHost(allowUrl: (url) => url.scheme == 'https'),
      onAction: _onAction,
    );
    setState(() {
      _busy = true;
      _status = 'Generating...';
    });
    final watch = Stopwatch()..start();
    final problems = await ui.generate(widget.model, [
      Message.user(_prompt.text),
    ]);
    if (!mounted) return ui.dispose();
    final old = _ui;
    setState(() {
      _busy = false;
      _ui = ui;
      _status = switch (problems) {
        [] => 'Built in ${watch.elapsed.inSeconds} s.',
        [final first, ...] => 'The model left a problem: ${first.message}',
      };
    });
    await WidgetsBinding.instance.endOfFrame;
    old?.dispose();
  }

  void _onAction(UiAction action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${action.name}: ${action.context}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = _ui;
    final surfaceId = ui?.surfaces.surfaces.keys.lastOrNull;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _prompt,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(
              labelText: 'Screen to build',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy ? null : _generate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Build'),
          ),
          const SizedBox(height: 8),
          Text(_status, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: switch ((ui, surfaceId)) {
                (final ui?, final id?) => UiSurfaceView(
                  controller: ui,
                  surfaceId: id,
                ),
                _ => const SizedBox.shrink(),
              },
            ),
          ),
        ],
      ),
    );
  }
}
