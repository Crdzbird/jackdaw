import 'package:jackdaw_web_bench/bench_screen.dart';
import 'package:jackdaw_web_bench/web_clock.dart';
import 'package:jackdaw_web_bench/web_side.dart';
import 'package:web/web.dart' as web;

/// Writes [updates] values to the screens [sides] hold in [hosts], the
/// sides taking turns one frame each, and returns per side the median and
/// slowest time from a write to the DOM showing it, and of the layout it
/// forces.
Future<Map<String, Map<String, Object>>> measureWrites(
  List<WebSide> sides,
  List<web.HTMLElement> hosts,
  int count,
  int updates,
) async {
  final changes = [
    for (final side in sides)
      [for (var i = 0; i < updates; i++) side.prepare(uiFrameWrite(i, count))],
  ];
  final costs = [
    for (final _ in sides)
      (apply: <double>[], dom: <double>[], layout: <double>[]),
  ];
  for (var i = 0; i < updates; i++) {
    for (var s = 0; s < sides.length; s++) {
      await nextFrame();
      final start = pageNow();
      sides[s].apply(changes[s][i]);
      final applied = pageNow() - start;
      final host = hosts[s];
      await settleUntil(() => host.textContent?.contains('Update $i') ?? false);
      final dom = pageNow() - start;
      host.offsetHeight;
      costs[s].apply.add(applied);
      costs[s].dom.add(dom);
      costs[s].layout.add(pageNow() - start - dom);
    }
  }
  double at(List<double> values, double p) =>
      (values..sort())[((values.length - 1) * p).round()];
  return {
    for (var s = 0; s < sides.length; s++)
      sides[s].name: {
        'write_apply_p50_ms': at(costs[s].apply, 0.5),
        'write_dom_p50_ms': at(costs[s].dom, 0.5),
        'write_dom_p99_ms': at(costs[s].dom, 0.99),
        'write_dom_max_ms': at(costs[s].dom, 1),
        'write_layout_p50_ms': at(costs[s].layout, 0.5),
        'write_layout_p99_ms': at(costs[s].layout, 0.99),
      },
  };
}
