/// Returns the [p] percentile of [values] in milliseconds, given values in
/// microseconds.
double percentileMs(List<int> values, double p) {
  final sorted = [...values]..sort();
  final index = ((sorted.length - 1) * p).round();
  return sorted[index] / 1000;
}
