import 'dart:async';

import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/tool/invoke_tool.dart';
import 'package:jackdaw/src/tool/tool_spec.dart';

/// A function the model can call, with typed and validated input.
///
/// Arguments are checked against [input] before they are decoded, so the
/// handler only ever sees well-formed data. Validation failures, thrown
/// errors and timeouts are returned to the model as error results instead
/// of failing the whole generation.
final class Tool<I> {
  /// Creates a tool named [name].
  ///
  /// [decode] turns validated JSON into [I], for example a `fromJson`
  /// constructor. [run] performs the work and returns JSON-encodable output.
  const factory({
    required String name,
    required String description,
    required ObjectSchema input,
    required I Function(Map<String, Object?> json) decode,
    required FutureOr<Object?> Function(I input) run,
    Duration timeout,
    bool requiresApproval,
    bool idempotent,
    int? maxCallsPerTurn,
  }) = Tool<I>._;

  const new _({
    required this.name,
    required this.description,
    required this.input,
    required this._decode,
    required this._run,
    this.timeout = const Duration(seconds: 30),
    this.requiresApproval = false,
    this.idempotent = false,
    this.maxCallsPerTurn,
  });

  /// Unique name the model uses to call the tool.
  final String name;

  /// When and why the model should use the tool.
  final String description;

  /// Schema of the arguments object.
  final ObjectSchema input;

  /// Longest time a single call may take.
  final Duration timeout;

  /// Whether the default policy waits for a person before running a call.
  final bool requiresApproval;

  /// Whether running a call twice is harmless. After an interruption, a
  /// call that may already have run is retried only when this is true.
  final bool idempotent;

  /// How many times a call may succeed before the model has to answer
  /// without the tool, counted from the last user message; `null` for no
  /// limit. Small models that keep calling a tool stop this way.
  final int? maxCallsPerTurn;

  final I Function(Map<String, Object?> json) _decode;
  final FutureOr<Object?> Function(I input) _run;

  /// The description sent to the model.
  ToolSpec get spec =>
      ToolSpec(name: name, description: description, input: input);

  /// Validates and runs [call], always completing with a result.
  Future<ToolResultPart> invoke(ToolCallPart call) => invokeTool(
    call,
    input: input,
    timeout: timeout,
    run: (json) => _run(_decode(json)),
  );
}
