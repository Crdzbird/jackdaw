import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_bench/src/bench_tools.dart';
import 'package:jackdaw_bench/src/tool_cases.dart';

/// Claim C2 for one model: share of well-formed tool calls, and how often
/// the model picks the right tool, the right arguments, or no tool.
Future<Map<String, Object>> runToolBench(LanguageModel model) async {
  var calls = 0;
  var wellFormed = 0;
  var rightChoice = 0;
  var rightArgs = 0;
  final misses = <String>[];
  for (final c in toolCases) {
    final request = ModelRequest(
      messages: [Message.user(c.prompt)],
      tools: benchTools,
      options: const GenerationOptions(maxOutputTokens: 120, temperature: 0),
    );
    List<ToolCallPart> made;
    try {
      final events = await model.generate(request).toList();
      made = [for (final e in events.whereType<ToolCallEvent>()) e.call];
    } on FormatException {
      calls++;
      misses.add('${c.prompt}: malformed call');
      continue;
    }
    calls += made.length;
    for (final call in made) {
      final spec = benchTools.where((t) => t.name == call.name).firstOrNull;
      if (spec != null && spec.input.validate(call.arguments).isEmpty) {
        wellFormed++;
      }
    }
    final chosen = made.isEmpty ? null : made.first.name;
    if (chosen != c.tool) {
      misses.add('${c.prompt}: wanted ${c.tool}, got $chosen');
      continue;
    }
    rightChoice++;
    final raw = made.isEmpty ? null : made.first.arguments;
    final args = raw is Map ? raw : const <Object?, Object?>{};
    final ok = c.args.entries.every(
      (e) => '${args[e.key]}'.toLowerCase() == '${e.value}'.toLowerCase(),
    );
    if (ok) rightArgs++;
    if (!ok) misses.add('${c.prompt}: arguments $args');
  }
  return {
    'model': model.id,
    'cases': toolCases.length,
    'calls': calls,
    'well_formed': calls == 0 ? 1.0 : wellFormed / calls,
    'right_choice': rightChoice / toolCases.length,
    'right_arguments': rightArgs / toolCases.length,
    'misses': misses,
  };
}
