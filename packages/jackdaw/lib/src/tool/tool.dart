import 'dart:async';

import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/schema/schema.dart';
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
  }) = Tool<I>._;

  const new _({
    required this.name,
    required this.description,
    required this.input,
    required this._decode,
    required this._run,
    this.timeout = const Duration(seconds: 30),
  });

  /// Unique name the model uses to call the tool.
  final String name;

  /// When and why the model should use the tool.
  final String description;

  /// Schema of the arguments object.
  final ObjectSchema input;

  /// Longest time a single call may take.
  final Duration timeout;

  final I Function(Map<String, Object?> json) _decode;
  final FutureOr<Object?> Function(I input) _run;

  /// The description sent to the model.
  ToolSpec get spec =>
      ToolSpec(name: name, description: description, input: input);

  /// Validates and runs [call], always completing with a result.
  Future<ToolResultPart> invoke(ToolCallPart call) async {
    final arguments = call.arguments;
    final violations = input.validate(arguments);
    if (violations.isNotEmpty || arguments is! Map) {
      return _failure(call, 'invalid arguments: ${violations.join('; ')}');
    }
    final json = Map<String, Object?>.from(arguments);
    try {
      final output = await Future<Object?>.sync(() => _run(_decode(json)))
          .timeout(timeout);
      return ToolResultPart(callId: call.id, name: name, output: output);
    } on TimeoutException {
      return _failure(call, 'timed out after ${timeout.inMilliseconds} ms');
    } on Object catch (error) {
      return _failure(call, '$error');
    }
  }

  ToolResultPart _failure(ToolCallPart call, String message) => ToolResultPart(
    callId: call.id,
    name: name,
    output: {'error': message},
    isError: true,
  );
}
