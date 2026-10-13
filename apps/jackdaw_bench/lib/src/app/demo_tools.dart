import 'dart:convert';
import 'dart:io';

import 'package:jackdaw/jackdaw.dart';

const ObjectSchema _none = ObjectSchema(properties: {});

/// Tools of the demo chat: the device clock, and notes kept in a file in
/// [folder]. Saving a note waits for the user's approval.
List<Tool<Object?>> demoTools(String folder) {
  final notes = File('$folder/notes.json');
  List<Object?> read() => notes.existsSync()
      ? jsonDecode(notes.readAsStringSync()) as List<Object?>
      : <Object?>[];
  return [
    Tool<Object?>(
      name: 'current_time',
      description: 'The current local date, time and weekday on the device.',
      input: _none,
      decode: (json) => json,
      run: (_) {
        final now = DateTime.now();
        return {
          'iso': now.toIso8601String(),
          'weekday': const [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ][now.weekday - 1],
        };
      },
      idempotent: true,
    ),
    Tool<Object?>(
      name: 'list_notes',
      description: 'Every note the user saved, oldest first.',
      input: _none,
      decode: (json) => json,
      run: (_) => {'notes': read()},
      idempotent: true,
    ),
    Tool<Object?>(
      name: 'save_note',
      description: 'Saves a short note for the user.',
      input: const ObjectSchema(
        properties: {'text': Schema.string(description: 'The note')},
        required: ['text'],
      ),
      decode: (json) => json['text']! as String,
      run: (text) {
        final all = [...read(), text];
        notes.writeAsStringSync(jsonEncode(all), flush: true);
        return {'saved': text, 'count': all.length};
      },
      requiresApproval: true,
    ),
  ];
}
