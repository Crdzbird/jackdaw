import 'dart:async';

import 'package:jackdaw/src/agent/agent.dart';
import 'package:jackdaw/src/agent/agent_runs.dart';
import 'package:jackdaw/src/agent/agent_stop_reason.dart';
import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/tool/tool.dart';

const Symbol _depthKey = #jackdaw.delegationDepth;

/// Wraps [agent] as a tool that another agent can hand a task to.
///
/// The sub-agent keeps its own tools and policy, and its final answer
/// becomes the tool result. Delegation deeper than [maxDepth] fails the
/// call, so agents that call each other cannot recurse without end. A
/// sub-agent that stops for approval fails the call too: approvals are
/// answered on the session that owns the tool, not inside a delegation.
Tool<String> delegateTo(
  Agent agent, {
  required String name,
  required String description,
  int maxDepth = 3,
}) => Tool<String>(
  name: name,
  description: description,
  input: const ObjectSchema(
    properties: {'task': Schema.string(description: 'What to do')},
    required: ['task'],
  ),
  decode: (json) => json['task']! as String,
  run: (task) async {
    final depth = (Zone.current[_depthKey] as int?) ?? 0;
    if (depth >= maxDepth) throw StateError('delegation deeper than $maxDepth');
    final done = await runZoned(
      () => agent.complete([Message.user(task)]),
      zoneValues: {_depthKey: depth + 1},
    );
    if (done.reason != AgentStopReason.completed) {
      throw StateError('$name stopped: ${done.reason.name}');
    }
    return done.text;
  },
  timeout: const Duration(minutes: 10),
);
