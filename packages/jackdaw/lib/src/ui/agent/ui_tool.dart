import 'package:jackdaw/src/schema/schema.dart';
import 'package:jackdaw/src/tool/tool.dart';
import 'package:jackdaw/src/tool/tool_failure.dart';
import 'package:jackdaw/src/ui/agent/ui_adopt_orphans.dart';
import 'package:jackdaw/src/ui/agent/ui_tree_messages.dart';
import 'package:jackdaw/src/ui/schema/ui_format.dart';
import 'package:jackdaw/src/ui/surface/ui_message_parts.dart';
import 'package:jackdaw/src/ui/surface/ui_problem.dart';
import 'package:jackdaw/src/ui/target/ui_target.dart';

/// A tool that shows and changes UI: the model calls it with a screen for
/// the catalog of [target] in [format], a tree by default or A2UI v1.0
/// messages, and [target] shows it as A2UI messages.
///
/// Creating a surface that exists replaces it, and with [adoptOrphans] a
/// new surface's components that nothing refers to are added to its
/// root's children. A call with problems changes nothing and fails with
/// them as A2UI `error` objects for the model to correct; otherwise the
/// result lists the surfaces shown and any warnings. After
/// [maxCallsPerTurn] successful calls the model answers in text, and
/// [onShown] hears the ids of the surfaces each successful call showed,
/// for example to redraw them. Local
/// models are held to the catalog by the reply grammar and read the
/// catalog guide as the description of the `messages` argument.
Tool<List<Object?>> uiTool(
  UiTarget target, {
  String name = 'render_ui',
  bool adoptOrphans = true,
  int? maxCallsPerTurn = 1,
  void Function(List<String> shown)? onShown,
  UiFormat format = UiFormat.tree,
}) => Tool(
  name: name,
  description:
      'Shows or changes UI on the screen with A2UI v1.0 messages. Use '
      'it whenever a screen, form or card explains the answer better '
      'than text.',
  input: format == UiFormat.tree
      ? target.schemas.tree
      : ObjectSchema(
          properties: {'messages': target.schemas.reply},
          required: ['messages'],
        ),
  decode: (json) => format == UiFormat.tree
      ? uiTreeMessages(json, target.schemas.catalog)
      : json['messages']! as List<Object?>,
  maxCallsPerTurn: maxCallsPerTurn,
  run: (sent) {
    final messages = adoptOrphans
        ? uiAdoptOrphans(sent, target.schemas.catalog)
        : sent;
    final result = _result(messages, target.show(messages));
    onShown?.call(result['shown']! as List<String>);
    return result;
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
