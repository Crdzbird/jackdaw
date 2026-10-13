@TestOn('vm')
library;

import 'dart:io';

import 'package:jackdaw/io.dart';
import 'package:jackdaw_cli/jackdaw_cli.dart';
import 'package:test/test.dart';

Future<String> _run(List<String> args, {int code = 0}) async {
  final out = StringBuffer();
  expect(await runCli(args, out), code, reason: '$out');
  return '$out';
}

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('jackdaw_cli'));
  tearDown(() => dir.delete(recursive: true));
  String file(String name, String text) =>
      (File('${dir.path}/$name')..writeAsStringSync(text)).path;

  test('trace lists spans with tokens, errors and totals', () async {
    final path = '${dir.path}/trace.jsonl';
    final tracer = JsonlTracer(File(path));
    tracer.startSpan('chat m')
      ..setAttribute('gen_ai.usage.input_tokens', 10)
      ..setAttribute('gen_ai.usage.output_tokens', 4)
      ..end();
    tracer.startSpan('execute_tool t').end(error: 'boom');
    tracer.startSpan('invoke_agent')
      ..setAttribute('gen_ai.usage.input_tokens', 10)
      ..end();
    File(path).writeAsStringSync('not json\n[1]\n', mode: FileMode.append);
    final out = await _run(['trace', path]);
    expect(out, contains(' ms  chat m  in=10 out=4'));
    expect(out, contains('execute_tool t  error: boom'));
    expect(out, endsWith('3 spans, 1 failed, 10 input and 4 output tokens\n'));
    await _run(['trace', '${dir.path}/none.jsonl'], code: 66);
    await _run(['trace'], code: 64);
  });

  test('grammar and validate read JSON Schema files', () async {
    final schema = file(
      's.json',
      '{"type":"object","properties":{"n":{"type":"integer"}},'
          '"required":["n"]}',
    );
    expect(await _run(['grammar', schema]), startsWith('root ::= rule0'));
    expect(
      await _run(['validate', schema, file('ok.json', '{"n":3}')]),
      'valid\n',
    );
    final bad = await _run([
      'validate',
      schema,
      file('bad.json', '{"n":"x"}'),
    ], code: 1);
    expect(bad, contains(r'$.n expected an integer'));
    expect(bad, endsWith('1 violations\n'));
    await _run(['grammar', file('list.json', '[1]')], code: 65);
    await _run(['grammar', file('broken.json', '{')], code: 65);
    await _run(['grammar', '${dir.path}/nothing.json'], code: 65);
    await _run(['validate', file('list2.json', '[1]'), schema], code: 65);
    await _run(['validate', schema, '${dir.path}/nothing.json'], code: 65);
    await _run(['grammar'], code: 64);
    await _run(['validate', schema], code: 64);
  });

  test('help and unknown commands print usage', () async {
    expect(await _run([]), contains('usage: jackdaw <command>'));
    expect(await _run(['help']), contains('inspect <session.jsonl>'));
    await _run(['fly'], code: 64);
  });
}
