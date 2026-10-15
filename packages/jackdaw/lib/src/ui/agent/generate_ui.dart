import 'dart:convert';

import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/model/generation_options.dart';
import 'package:jackdaw/src/model/language_model.dart';
import 'package:jackdaw/src/structured/generate_json.dart';
import 'package:jackdaw/src/ui/agent/ui_adopt_orphans.dart';
import 'package:jackdaw/src/ui/agent/ui_tree_messages.dart';
import 'package:jackdaw/src/ui/schema/ui_format.dart';
import 'package:jackdaw/src/ui/surface/ui_problem.dart';
import 'package:jackdaw/src/ui/target/ui_target.dart';

/// Asks [model] for UI as its whole answer in [format], a tree by default,
/// and shows it on [target].
///
/// The answer is held to the schema of the catalog; [adoptOrphans]
/// works as it does for `uiTool`, and creating a surface that exists
/// replaces it. When applying
/// it finds problems, the model is told what is wrong and asked again, up
/// to [repairs] times; an attempt with problems beyond warnings changes
/// nothing, and the last one is shown as well as it can be. Returns the
/// problems of the last attempt, which are only warnings on success.
/// [onReply] receives the answer that was shown, so a follow-up request
/// can carry it as the assistant's turn and change that screen.
Future<List<UiProblem>> generateUi(
  LanguageModel model,
  List<Message> messages,
  UiTarget target, {
  GenerationOptions options = const GenerationOptions(maxOutputTokens: 1024),
  int repairs = 1,
  bool adoptOrphans = true,
  UiFormat format = UiFormat.tree,
  void Function(Object? reply)? onReply,
}) async {
  final conversation = [...messages];
  for (var attempt = 0; ; attempt++) {
    final reply = await generateJson(
      model,
      conversation,
      format == UiFormat.tree ? target.schemas.tree : target.schemas.reply,
      options: options,
    );
    final last = attempt >= repairs;
    final sent = format == UiFormat.tree
        ? uiTreeMessages(reply! as Map<String, Object?>, target.schemas.catalog)
        : reply! as List<Object?>;
    final problems = target.show(
      adoptOrphans ? uiAdoptOrphans(sent, target.schemas.catalog) : sent,
      partial: last,
    );
    if (problems.every((p) => p.warning) || last) {
      onReply?.call(reply);
      return problems;
    }
    conversation
      ..add(Message.assistant(jsonEncode(reply)))
      ..add(Message.user(_repair(problems)));
  }
}

String _repair(List<UiProblem> problems) => [
  'That UI has problems. Send the whole corrected answer again:',
  for (final p in problems) '- ${p.path.isEmpty ? '/' : p.path}: ${p.message}',
].join('\n');
