/// How far a model download has come.
final class ModelDownloadProgress {
  /// [received] of [total] bytes are on disk; with [checking], all of
  /// them are and the hash is being checked.
  const factory(int received, int total, {bool checking}) =
      ModelDownloadProgress._;

  const new _(this.received, this.total, {this.checking = false});

  /// Bytes on disk, counting those of an earlier, interrupted download.
  final int received;

  /// The size of the whole file.
  final int total;

  /// Whether every byte is in and the SHA-256 is being checked.
  final bool checking;

  /// The share received, from 0 to 1.
  double get fraction => total == 0 ? 1 : received / total;
}
