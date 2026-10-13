import 'package:jackdaw/src/agent/agent.dart';
import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/model/model_request.dart';
import 'package:jackdaw/src/tool/tool_spec.dart';

/// The request [agent] sends for [messages]: instructions first, then the
/// transcript cut to the agent's context budget.
ModelRequest agentRequest(
  Agent agent,
  List<ToolSpec> tools,
  List<Message> messages,
) => ModelRequest(
  messages: List.unmodifiable([
    if (agent.instructions case final text?) Message.system(text),
    ...(agent.budget?.fit(messages) ?? messages),
  ]),
  tools: tools,
  options: agent.options,
);
