import 'package:flutter/material.dart';
import 'package:jackdaw_flutter/src/ui/builders/ui_leaf.dart';
import 'package:jackdaw_flutter/src/ui/ui_node.dart';
import 'package:jackdaw_flutter/src/ui/ui_node_values.dart';

/// A Slider component bound to the data model.
Widget uiSliderWidget(UiNode node) {
  final min = node.number('min') ?? 0;
  final max = (node.number('max') ?? 1).clamp(min, double.infinity);
  final steps = node.number('steps')?.round();
  final label = node.text('label');
  return uiLeaf(
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) Text(label),
        Slider(
          value: (node.number('value') ?? min).clamp(min, max),
          min: min,
          max: max,
          divisions: steps == null || steps < 1 || max == min ? null : steps,
          label: label,
          onChanged: max == min ? null : (value) => node.write('value', value),
        ),
      ],
    ),
  );
}

/// A DateTimeInput component: a tile that picks a date, a time or both
/// and writes an ISO 8601 value.
Widget uiDateTimeWidget(UiNode node) => Builder(
  builder: (context) {
    final value = node.text('value');
    return uiLeaf(
      ListTile(
        title: Text(node.text('label') ?? 'Date'),
        subtitle: Text(value == null || value.isEmpty ? 'Not set' : value),
        trailing: const Icon(Icons.calendar_today),
        onTap: () => _pick(context, node),
      ),
    );
  },
);

Future<void> _pick(BuildContext context, UiNode node) async {
  final time = node.truth('enableTime');
  final date = node.truth('enableDate') || !time;
  final current = DateTime.tryParse(node.text('value') ?? '') ?? DateTime.now();
  final day = date
      ? await showDatePicker(
          context: context,
          initialDate: current,
          firstDate:
              DateTime.tryParse(node.text('min') ?? '') ?? DateTime(1900),
          lastDate: DateTime.tryParse(node.text('max') ?? '') ?? DateTime(2100),
        )
      : current;
  if (day == null || !context.mounted) return;
  final clock = time
      ? await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(current),
        )
      : null;
  if (time && clock == null) return;
  String two(int n) => '$n'.padLeft(2, '0');
  final ymd = '${day.year}-${two(day.month)}-${two(day.day)}';
  final hm = clock == null ? '' : '${two(clock.hour)}:${two(clock.minute)}';
  node.write('value', switch ((date, time)) {
    (true, true) => '${ymd}T$hm:00',
    (false, true) => hm,
    _ => ymd,
  });
}
