import 'dart:async';

const Symbol _callKey = #jackdaw.toolCallId;

/// Information about the tool call currently running.
abstract final class ToolContext {
  /// Identifier of the running call, or `null` outside a tool.
  ///
  /// Use it as an idempotency key with external services, so a call that
  /// is retried after an interruption is not carried out twice.
  static String? get callId => Zone.current[_callKey] as String?;

  /// Runs [body] with [callId] as the current call.
  static R run<R>(String callId, R Function() body) =>
      runZoned(body, zoneValues: {_callKey: callId});
}
