import 'dart:io';

/// A model download that failed: the server refused it, or the bytes do
/// not match the expected size or SHA-256.
final class ModelDownloadException implements IOException {
  /// Creates the exception with [message] about [url].
  const factory(String message, {Uri? url}) = ModelDownloadException._;

  const new _(this.message, {this.url});

  /// What went wrong.
  final String message;

  /// The address that was being downloaded.
  final Uri? url;

  @override
  String toString() => switch (url) {
    null => 'ModelDownloadException: $message',
    final url => 'ModelDownloadException: $message ($url)',
  };
}
