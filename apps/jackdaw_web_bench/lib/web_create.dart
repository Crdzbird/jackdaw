import 'dart:js_interop';

import 'package:jackdaw_web_bench/bench_screen.dart';
import 'package:jackdaw_web_bench/web_clock.dart';
import 'package:jackdaw_web_bench/web_side.dart';
import 'package:web/web.dart' as web;

/// Draws a screen of [count] components with [side] into [host] and
/// returns the times from the messages to the drawn DOM, to the end of
/// the layout it forces and to the next frame, with the elements and,
/// with [memory], the memory the screen added and its HTML.
Future<Map<String, Object>> measureCreate(
  WebSide side,
  web.HTMLElement host,
  int count, {
  bool memory = false,
}) async {
  final left = side.mount(host, side.prepare(uiFrameSurface(count)));
  await nextFrame();
  await nextFrame();
  final before = memory ? await pageMemory() : 0;
  await nextFrame();
  final start = pageNow();
  side.apply(left);
  final applied = pageNow() - start;
  bool drawn() => [
    'Value 35',
    'Field 36',
    'Box 37',
  ].every((t) => host.textContent?.contains(t) ?? false);
  final shown = await settleUntil(drawn);
  final dom = pageNow() - start;
  host.offsetHeight;
  final laid = pageNow() - start;
  await nextFrame();
  final framed = pageNow() - start;
  if (!shown) throw StateError('${side.name} did not draw the screen');
  return {
    'apply_ms': applied,
    'dom_ms': dom,
    'layout_ms': laid - dom,
    'to_frame_ms': framed,
    'elements': host.getElementsByTagName('*').length,
    if (memory) 'memory_kb': (await pageMemory() - before) / 1024,
    if (memory) 'html': (host.innerHTML as JSString).toDart,
  };
}
