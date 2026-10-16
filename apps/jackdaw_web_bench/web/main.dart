import 'dart:convert';
import 'dart:js_interop';

import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jackdaw_dom/jackdaw_dom.dart';
import 'package:jackdaw_web_bench/genui_jaspr_side.dart';
import 'package:jackdaw_web_bench/jackdaw_dom_side.dart';
import 'package:jackdaw_web_bench/jaspr_host.dart';
import 'package:jackdaw_web_bench/web_create.dart';
import 'package:jackdaw_web_bench/web_side.dart';
import 'package:jackdaw_web_bench/web_writes.dart';
import 'package:jaspr/client.dart';
import 'package:web/web.dart' as web;

const _rounds = 10;

Future<void> main() async {
  try {
    await _run();
  } on Object catch (error, stack) {
    await _post('/result', [
      {'error': '$error', 'stack': '$stack'},
    ]);
  }
}

Future<void> _post(String path, Object body) => web.window
    .fetch(
      path.toJS,
      web.RequestInit(method: 'POST', body: jsonEncode(body).toJS),
    )
    .toDart;

Future<void> _run() async {
  final styles = web.HTMLStyleElement()
    ..textContent = [
      uiDomStyles,
      for (final rule in BasicJasprCatalog().styles) rule.toCss(),
    ].join('\n');
  web.document.head!.append(styles);
  runApp(const JasprHost(), attachTo: '#genui_jaspr');
  final hosts = {
    for (final id in ['jackdaw_dom', 'genui_jaspr'])
      id: web.document.getElementById(id)! as web.HTMLElement,
  };
  final rows = <Map<String, Object>>[];
  for (var round = 0; round <= _rounds; round++) {
    await _post('/log', 'round $round');
    final made = <WebSide>[JackdawDomSide(), GenuiJasprSide()];
    final sides = round.isEven ? made : made.reversed.toList();
    final created = {
      for (final side in sides)
        side.name: await measureCreate(side, hosts[side.name]!, 40),
    };
    final written = await measureWrites(
      sides,
      [for (final side in sides) hosts[side.name]!],
      40,
      120,
    );
    for (final side in made) {
      if (round > 0) {
        rows.add({
          'side': side.name,
          ...created[side.name]!,
          ...written[side.name]!,
        });
      }
      side.dispose();
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  for (var round = 0; round < 4; round++) {
    for (final side in <WebSide>[JackdawDomSide(), GenuiJasprSide()]) {
      final measured = await measureCreate(
        side,
        hosts[side.name]!,
        40,
        memory: true,
      );
      if (round > 0) rows.add({'side': '${side.name}.memory', ...measured});
      side.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
  await _post('/result', rows);
}
