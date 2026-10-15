import 'package:flutter/material.dart';

/// The request box of the UI tab, with its buttons and status line.
class UiStudioBar extends StatelessWidget {
  const new({
    required this.prompt,
    required this.status,
    required this.busy,
    required this.official,
    required this.onOfficial,
    required this.onBuild,
    required this.onReset,
    super.key,
  });

  /// The request being written.
  final TextEditingController prompt;

  /// What happened last.
  final String status;

  /// Whether a screen is being built.
  final bool busy;

  /// Whether the official genui package draws the screen.
  final bool official;

  /// Switches between jackdaw_flutter and genui.
  final ValueChanged<bool> onOfficial;

  /// Builds or changes the screen.
  final VoidCallback onBuild;

  /// Forgets the screen, so the next request starts a new one.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('jackdaw_flutter')),
          ButtonSegment(value: true, label: Text('genui (official)')),
        ],
        selected: {official},
        onSelectionChanged: busy ? null : (set) => onOfficial(set.single),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: prompt,
        maxLines: 3,
        minLines: 1,
        decoration: const InputDecoration(
          labelText: 'Describe a screen, or a change to it',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: busy ? null : onBuild,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Build'),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: busy ? null : onReset,
            child: const Text('New screen'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(status, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
