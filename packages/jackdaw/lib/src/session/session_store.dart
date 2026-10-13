import 'package:jackdaw/src/session/session_record.dart';

/// Persists the append-only journal of agent sessions.
///
/// Implementations must make [append] durable before its future completes,
/// so a session can resume after the process dies at any point.
abstract interface class SessionStore {
  /// Returns every record of [sessionId], oldest first; empty when unknown.
  Future<List<SessionRecord>> load(String sessionId);

  /// Appends [record] to [sessionId].
  Future<void> append(String sessionId, SessionRecord record);
}
