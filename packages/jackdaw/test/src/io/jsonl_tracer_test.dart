@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:jackdaw/io.dart';
import 'package:test/test.dart';

void main() {
  test('finished spans are appended as JSON lines', () async {
    final dir = await Directory.systemTemp.createTemp('jackdaw_trace');
    final file = File('${dir.path}/trace.jsonl');
    final tracer = JsonlTracer(file);
    tracer.startSpan('chat m', attributes: {'gen_ai.request.model': 'm'})
      ..setAttribute('odd', DateTime.utc(2026))
      ..end();
    tracer.startSpan('execute_tool t').end(error: StateError('broke'));
    final lines = [
      for (final line in await file.readAsLines()) jsonDecode(line) as Map,
    ];
    expect(lines.map((l) => l['name']), ['chat m', 'execute_tool t']);
    expect((lines.first['attributes'] as Map)['odd'], startsWith('2026-01-01'));
    expect(lines.first['duration_us'], isA<int>());
    expect(lines.first.containsKey('error'), isFalse);
    expect(lines.last['error'], contains('broke'));
    expect(DateTime.parse(lines.last['start'] as String).isUtc, isTrue);
    await dir.delete(recursive: true);
  });
}
