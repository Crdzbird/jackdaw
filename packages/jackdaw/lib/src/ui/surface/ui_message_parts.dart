/// The kind of the A2UI message [message], such as `createSurface`, and
/// its body, or `null` when it is not a message envelope.
(String, Map<String, Object?>)? uiMessageParts(Object? message) {
  if (message is! Map<String, Object?>) return null;
  for (final MapEntry(:key, :value) in message.entries) {
    if (key != 'version' && value is Map<String, Object?>) return (key, value);
  }
  return null;
}
