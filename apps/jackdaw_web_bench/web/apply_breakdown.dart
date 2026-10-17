import 'dart:convert';
import 'dart:js_interop';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:genui_jaspr/genui_jaspr.dart';
import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_dom/jackdaw_dom.dart';
import 'package:jackdaw_web_bench/bench_screen.dart';
import 'package:jackdaw_web_bench/web_clock.dart';
import 'package:web/web.dart' as web;

/// Times each step of applying the bench screen's messages, on fresh
/// surfaces each time, to find where jackdaw spends its apply.
Future<void> main() async {
  final message = uiFrameSurface(40);
  final lowered = uiLowerToV09([message], basicCatalog);
  final schema = UiSurfaces(basicCatalog).schemas.message;
  final steps = <String, double Function()>{
    'jackdaw UiDomController.applyAll': () {
      final ui = UiDomController(basicCatalog);
      final start = pageNow();
      ui.applyAll([message]);
      return pageNow() - start;
    },
    'jackdaw UiSurfaces.applyAll': () {
      final surfaces = UiSurfaces(basicCatalog);
      final start = pageNow();
      surfaces.applyAll([message]);
      return pageNow() - start;
    },
    'jackdaw schema accepts': () {
      final start = pageNow();
      schema.accepts(message);
      return pageNow() - start;
    },
    'jackdaw tree problems': () {
      final surfaces = UiSurfaces(basicCatalog)..applyAll([message]);
      final surface = surfaces.surfaces['bench']!;
      final start = pageNow();
      uiTreeProblems(surface);
      return pageNow() - start;
    },
    'jackdaw components and data': () {
      final start = pageNow();
      final body = message['createSurface']! as Map<String, Object?>;
      for (final item in body['components']! as List<Object?>) {
        UiComponent.fromJson(item! as Map<String, Object?>);
      }
      UiDataModel(body['dataModel']);
      return pageNow() - start;
    },
    'genui_jaspr parse and process': () {
      final processor = MessageProcessor<JasprComponent>(
        catalogs: [BasicJasprCatalog()],
      );
      final start = pageNow();
      processor.processMessages([
        for (final m in lowered) A2uiMessage.fromJson(m),
      ]);
      return pageNow() - start;
    },
  };
  final rows = <Map<String, Object>>[];
  for (var round = 0; round < 330; round++) {
    for (final MapEntry(:key, :value) in steps.entries) {
      final ms = value();
      if (round >= 30) rows.add({'side': key, 'ms': ms});
    }
    if (round % 30 == 0) await nextFrame();
  }
  final keys = steps.keys.toList();
  for (var round = 0; round < 60; round++) {
    final key = keys[round % keys.length];
    final junk = <List<int>>[];
    for (var i = 0; i < 2000; i++) {
      junk.add(List<int>.generate(64, (n) => n * i));
    }
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final ms = steps[key]!();
    rows.add({'side': 'cold $key', 'ms': ms + junk.length * 0});
  }
  await web.window
      .fetch(
        '/result'.toJS,
        web.RequestInit(method: 'POST', body: jsonEncode(rows).toJS),
      )
      .toDart;
}
