/// Why an agent run ended.
enum AgentStopReason {
  /// The model answered without asking for more tools.
  completed,

  /// The run hit the agent's step limit.
  stepLimit,

  /// A tool call waits for a person's approval; continue with
  /// `Agent.decide`.
  awaitingApproval,
}
