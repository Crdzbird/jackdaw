import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/message/part.dart';

part 'approval_decided_record.dart';
part 'approval_requested_record.dart';
part 'message_record.dart';
part 'tool_result_record.dart';
part 'tool_started_record.dart';

/// One entry of a session's append-only journal.
///
/// A session's state is rebuilt by replaying its records in order, so a
/// run interrupted at any point can resume without repeating finished work.
sealed class SessionRecord {
  const new _();
}
