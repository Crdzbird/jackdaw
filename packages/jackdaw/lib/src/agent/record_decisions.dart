import 'package:jackdaw/src/agent/approval_decision.dart';
import 'package:jackdaw/src/session/session_record.dart';
import 'package:jackdaw/src/session/session_state.dart';
import 'package:jackdaw/src/session/session_store.dart';

/// Journals [decisions] for calls of [sessionId] that wait for approval.
///
/// Every decision is checked before any is written: an id that is not
/// pending throws [ArgumentError], so a client can neither approve a call
/// the policy never asked about nor change the arguments that will run.
Future<void> recordDecisions(
  SessionStore store,
  String sessionId,
  Map<String, ApprovalDecision> decisions,
) async {
  final pending = SessionState(await store.load(sessionId)).awaiting;
  for (final id in decisions.keys) {
    if (!pending.contains(id)) {
      throw ArgumentError.value(id, 'decisions', 'no pending approval');
    }
  }
  for (final MapEntry(:key, :value) in decisions.entries) {
    await store.append(
      sessionId,
      ApprovalDecidedRecord(key, granted: value.granted, note: value.note),
    );
  }
}
