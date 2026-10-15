import 'dart:convert';

import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/model/generation_options.dart';
import 'package:jackdaw/src/model/language_model.dart';
import 'package:jackdaw/src/structured/generate_json.dart';
import 'package:jackdaw/src/ui/agent/ui_adopt_orphans.dart';
import 'package:jackdaw/src/ui/surface/ui_problem.dart';
import 'package:jackdaw/src/ui/surface/ui_surfaces.dart';

/// Asks [model] for UI as its whole answer and applies it to [surfaces].
///
/// The answer is held to the reply schema of the catalog; [adoptOrphans]
/// works as it does for `uiTool`, and creating a surface that exists
/// replaces it. When applying
/// it finds problems, the model is told what is wrong and asked again, up
/// to [repairs] times; an attempt with problems beyond warnings changes
/// nothing, and the last one is shown as well as it can be. Returns the
/// problems of the last attempt, which are only warnings on success.
Future<List<UiProblem>> generateUi(
  LanguageModel model,
  List<Message> messages,
  UiSurfaces surfaces, {
  GenerationOptions options = const GenerationOptions(maxOutputTokens: 1024),
  int repairs = 1,
  bool adoptOrphans = true,
}) async {
  final conversation = [...messages];
  for (var attempt = 0; ; attempt++) {
    final reply = await generateJson(
      model,
      conversation,
      surfaces.schemas.reply,
      options: options,
    );
    final last = attempt >= repairs;
    final sent = reply! as List<Object?>;
    final problems = surfaces.applyAll(
      adoptOrphans ? uiAdoptOrphans(sent, surfaces.catalog) : sent,
      atomic: !last,
      replace: true,
    );
    if (problems.every((p) => p.warning) || last) return problems;
    conversation
      ..add(Message.assistant(jsonEncode(reply)))
      ..add(Message.user(_repair(problems)));
  }
}

String _repair(List<UiProblem> problems) => [
  'That UI has problems. Send the whole corrected answer again:',
  for (final p in problems) '- ${p.path.isEmpty ? '/' : p.path}: ${p.message}',
].join('\n');
