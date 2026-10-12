import 'package:jackdaw/src/agent/agent_stop_reason.dart';
import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/model/usage.dart';

part 'agent_finished.dart';
part 'agent_text_delta.dart';
part 'agent_tool_call.dart';
part 'agent_tool_result.dart';

/// One event in the stream produced by an agent run.
sealed class AgentEvent {
  const new _();
}
