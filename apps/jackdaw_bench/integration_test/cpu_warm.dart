/// Keeps the UI thread busy for 200 ms, as the end of a generation does, so
/// the screen is built on a core at its working clock. After the idle wait
/// the cores clock down, and a frame built at once runs up to ten times
/// slower, which made the side that applies faster look slower.
void warmCpu() {
  final spin = Stopwatch()..start();
  var sink = 0;
  while (spin.elapsedMilliseconds < 200) {
    sink = (sink + spin.elapsedMicroseconds) & 0xffff;
  }
  if (sink < 0) throw StateError('unreachable');
}
