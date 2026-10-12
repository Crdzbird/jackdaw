import 'package:flutter/material.dart';

/// Generate and stop buttons plus the JSON mode switch.
class ControlsRow extends StatelessWidget {
  const new({
    required this.busy,
    required this.json,
    required this.onGenerate,
    required this.onStop,
    required this.onJson,
    super.key,
  });

  final bool busy;
  final bool json;
  final VoidCallback onGenerate;
  final VoidCallback onStop;
  final ValueChanged<bool> onJson;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      FilledButton(
        onPressed: busy ? null : onGenerate,
        child: const Text('Generate'),
      ),
      const SizedBox(width: 8),
      OutlinedButton(
        onPressed: busy ? onStop : null,
        child: const Text('Stop'),
      ),
      const Spacer(),
      const Text('JSON'),
      Switch(value: json, onChanged: busy ? null : onJson),
    ],
  );
}
