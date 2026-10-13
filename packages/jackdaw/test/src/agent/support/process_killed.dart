/// Thrown by `CrashingStore` to stand in for the process dying.
final class ProcessKilled implements Exception {
  const factory() = ProcessKilled._;

  const new _();
}
