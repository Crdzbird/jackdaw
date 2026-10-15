import 'dart:ui';

/// Frame time percentiles of [frames] and the frames over the budget of
/// a display refreshing [rate] times a second.
Map<String, Object> frameSummary(List<FrameTiming> frames, double rate) {
  final budget = 1e6 / rate;
  List<int> sorted(Iterable<Duration> values) =>
      [for (final d in values) d.inMicroseconds]..sort();
  double at(List<int> values, double p) =>
      values.isEmpty ? 0 : values[((values.length - 1) * p).round()] / 1000;
  final build = sorted(frames.map((f) => f.buildDuration));
  final raster = sorted(frames.map((f) => f.rasterDuration));
  return {
    'frames': frames.length,
    'build_p50_ms': at(build, 0.5),
    'build_p99_ms': at(build, 0.99),
    'build_max_ms': at(build, 1),
    'raster_p99_ms': at(raster, 0.99),
    'build_over_budget': build.where((b) => b > budget).length,
    'total_over_budget': frames
        .where((f) => f.totalSpan.inMicroseconds > budget)
        .length,
    'slow_frames': _slow(frames, budget),
  };
}

List<String> _slow(List<FrameTiming> frames, double budget) {
  if (frames.isEmpty) return const [];
  int at(FrameTiming f) => f.timestampInMicroseconds(FramePhase.vsyncStart);
  final start = at(frames.first);
  final end = (at(frames.last) - start) ~/ 1000;
  String describe(FrameTiming f) =>
      '${f.buildDuration.inMicroseconds / 1000} ms at '
      '${(at(f) - start) ~/ 1000} of $end';
  return [
    for (final f in frames)
      if (f.buildDuration.inMicroseconds > budget) describe(f),
  ];
}
