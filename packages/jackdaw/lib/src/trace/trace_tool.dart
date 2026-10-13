import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/tool/tool.dart';
import 'package:jackdaw/src/trace/tracer.dart';

/// Runs [call] on [tool] inside an `execute_tool` span from [tracer].
///
/// Arguments and output are attached only when [content] is true. A failed
/// call ends its span with the error the model is shown.
Future<ToolResultPart> traceTool(
  Tracer tracer,
  Tool<Object?> tool,
  ToolCallPart call, {
  bool content = false,
}) async {
  final span = tracer.startSpan(
    'execute_tool ${tool.name}',
    attributes: {
      'gen_ai.operation.name': 'execute_tool',
      'gen_ai.tool.name': tool.name,
      'gen_ai.tool.call.id': call.id,
      if (content) 'gen_ai.tool.call.arguments': call.arguments,
    },
  );
  final result = await tool.invoke(call);
  if (content) span.setAttribute('gen_ai.tool.call.result', result.output);
  span.end(error: result.isError ? result.output : null);
  return result;
}
