import 'dart:convert';

import 'package:jackdaw/jackdaw.dart';
import 'package:test/test.dart';

Future<List<SseEvent>> decode(List<List<int>> chunks, {int? max}) {
  final decoder = max == null
      ? const SseDecoder()
      : SseDecoder(maxEventLength: max);
  return Stream.fromIterable(chunks).transform(decoder).toList();
}

final eAcute = String.fromCharCode(0xE9);

void main() {
  test('joins multi-line data and reads event and id', () async {
    final events = await decode([
      utf8.encode('event: delta\r\nid: 7\r\ndata: a\r\ndata:b\r\n\r\n'),
    ]);
    expect(events.single.event, 'delta');
    expect(events.single.id, '7');
    expect(events.single.data, 'a\nb');
  });

  test('handles characters split across chunks', () async {
    final bytes = utf8.encode('data: caf$eAcute\n\n');
    final events = await decode([
      bytes.sublist(0, bytes.length - 3),
      bytes.sublist(bytes.length - 3),
    ]);
    expect(events.single.data, 'caf$eAcute');
  });

  test('skips comments, unknown fields and empty events', () async {
    final events = await decode([
      utf8.encode(': ping\nretry: 10\n\ndata\n\ndata: last'),
    ]);
    expect(events.map((e) => e.data), ['', 'last']);
    expect(events.first.event, 'message');
  });

  test('rejects events above the size limit', () {
    expect(
      decode([utf8.encode('data: 0123456789\n\n')], max: 4),
      throwsA(isA<FormatException>()),
    );
  });
}
