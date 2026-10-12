/// Parses an HTTP `Retry-After` header given in seconds.
///
/// Returns `null` when [value] is absent, negative or not a whole number of
/// seconds.
Duration? parseRetryAfter(String? value) {
  final seconds = int.tryParse(value?.trim() ?? '');
  if (seconds == null || seconds < 0) return null;
  return Duration(seconds: seconds);
}
