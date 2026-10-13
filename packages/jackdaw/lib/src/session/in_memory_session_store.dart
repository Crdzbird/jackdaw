import 'package:jackdaw/src/session/session_record.dart';
import 'package:jackdaw/src/session/session_store.dart';

/// A [SessionStore] that keeps journals in memory; lost when the process
/// ends. Suits tests, web apps without persistence and one-off runs.
final class InMemorySessionStore implements SessionStore {
  /// Creates an empty store.
  factory() = InMemorySessionStore._;

  new _();

  final Map<String, List<SessionRecord>> _sessions = {};

  @override
  Future<List<SessionRecord>> load(String sessionId) async =>
      List.unmodifiable(_sessions[sessionId] ?? const []);

  @override
  Future<void> append(String sessionId, SessionRecord record) async {
    (_sessions[sessionId] ??= []).add(record);
  }
}
