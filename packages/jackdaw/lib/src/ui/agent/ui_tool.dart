import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/tool/tool.dart';
import 'package:jackdaw/src/tool/tool_failure.dart';
import 'package:jackdaw/src/ui/agent/ui_adopt_orphans.dart';
import 'package:jackdaw/src/ui/surface/ui_message_parts.dart';
import 'package:jackdaw/src/ui/surface/ui_problem.dart';
import 'package:jackdaw/src/ui/surface/ui_surfaces.dart';

/// A tool that shows and changes UI: the model calls it with A2UI v1.0
/// messages for the catalog of [surfaces], which applies them.
///
/// Creating a surface that exists replaces it, and with [adoptOrphans] a
/// new surface's components that nothing refers to are added to its
/// root's children. A call with problems changes nothing and fails with
/// them as A2UI `error` objects for the model to correct; otherwise the
/// result lists the surfaces shown and any warnings. After
/// [maxCallsPerTurn] successful calls the model answers in text. Local
/// models are held to the catalog by the reply grammar and read the
/// catalog guide as the description of the `messages` argument.
Tool<List<Object?>> uiTool(
  UiSurfaces surfaces, {
  String name = 'render_ui',
  bool adoptOrphans = true,
  int? maxCallsPerTurn = 1,
}) => Tool(
  name: name,
  description:
      'Shows or changes UI on the screen with A2UI v1.0 messages. Use '
      'it whenever a screen, form or card explains the answer better '
      'than text.',
  input: ObjectSchema(
    properties: {'messages': surfaces.schemas.reply},
    required: ['messages'],
  ),
  decode: (json) => json['messages']! as List<Object?>,
  maxCallsPerTurn: maxCallsPerTurn,
  run: (sent) {
    final messages = adoptOrphans
        ? uiAdoptOrphans(sent, surfaces.catalog)
        : sent;
    return _result(
      messages,
      surfaces.applyAll(messages, atomic: true, replace: true),
    );
  },
);

Map<String, Object?> _result(List<Object?> messages, List<UiProblem> found) {
  List<Object?> errors(bool Function(UiProblem) which) => [
    for (final p in found.where(which)) p.toJson()['error'],
  ];
  final problems = errors((p) => !p.warning);
  if (problems.isNotEmpty) {
    throw ToolFailure({
      'shown': const <String>[],
      'note': 'Nothing was shown. Send every message again, corrected.',
      'problems': problems,
    });
  }
  final warnings = errors((p) => p.warning);
  return {
    'note':
        'The user sees it now. Answer in text, and call again only to '
        'change it.',
    if (warnings.isNotEmpty) 'warnings': warnings,
    'shown': {
      for (final message in messages)
        if (uiMessageParts(message) case (_, {'surfaceId': final String id}))
          id,
    }.toList(),
  };
}
