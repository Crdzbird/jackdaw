import 'package:flutter/material.dart';

/// The options [shown] as [chips], checkboxes, or radio buttons when the
/// choice is [exclusive], with [chosen] selected; [choose] hears each
/// option turned on or off.
Widget uiChoiceList({
  required bool chips,
  required bool exclusive,
  required List<(String, String)> shown,
  required Set<String> chosen,
  required void Function(String value, {required bool on}) choose,
}) {
  if (chips) {
    return Wrap(
      spacing: 8,
      children: [
        for (final (label, value) in shown)
          FilterChip(
            label: Text(label),
            selected: chosen.contains(value),
            onSelected: (on) => choose(value, on: on),
          ),
      ],
    );
  }
  if (!exclusive) {
    return Column(
      children: [
        for (final (label, value) in shown)
          CheckboxListTile(
            title: Text(label),
            value: chosen.contains(value),
            onChanged: (on) => choose(value, on: on ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          ),
      ],
    );
  }
  return RadioGroup<String>(
    groupValue: chosen.firstOrNull,
    onChanged: (value) => choose(value ?? '', on: value != null),
    child: Column(
      children: [
        for (final (label, value) in shown)
          RadioListTile<String>(title: Text(label), value: value, dense: true),
      ],
    ),
  );
}
