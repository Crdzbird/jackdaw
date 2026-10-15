import 'dart:async';

import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/tool/tool_context.dart';
import 'package:jackdaw/src/tool/tool_failure.dart';

/// Validates [call] against [input] and runs [run] on its arguments within
/// [timeout], always completing with a result. Invalid arguments, thrown
/// errors, a [ToolFailure] and timeouts become error results.
Future<ToolResultPart> invokeTool(
  ToolCallPart call, {
  required ObjectSchema input,
  required Duration timeout,
  required FutureOr<Object?> Function(Map<String, Object?> json) run,
}) async {
  ToolResultPart failure(Object? output) => ToolResultPart(
    callId: call.id,
    name: call.name,
    output: output,
    isError: true,
  );
  final arguments = call.arguments;
  final violations = input.validate(arguments);
  if (violations.isNotEmpty || arguments is! Map) {
    return failure({'error': 'invalid arguments: ${violations.join('; ')}'});
  }
  final json = Map<String, Object?>.from(arguments);
  try {
    final output = await ToolContext.run(
      call.id,
      () => Future<Object?>.sync(() => run(json)),
    ).timeout(timeout);
    return ToolResultPart(callId: call.id, name: call.name, output: output);
  } on TimeoutException {
    return failure({'error': 'timed out after ${timeout.inMilliseconds} ms'});
  } on ToolFailure catch (e) {
    return failure(e.output);
  } on Object catch (error) {
    return failure({'error': '$error'});
  }
}
