import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/ui/agent/ui_adopt_orphans.dart';
import 'package:jackdaw/src/ui/agent/ui_tree_messages.dart';
import 'package:jackdaw/src/ui/target/ui_target.dart';

/// Rebuilds the surfaces of [target] from [history], such as a restored
/// session: every successful call of the tool named [tool] is shown again
/// in order, as `uiTool` showed it.
///
/// What the user entered is not in the transcript, so inputs come back
/// with the values the agent last sent.
void uiReplay(
  UiTarget target,
  List<Message> history, {
  String tool = 'render_ui',
  bool adoptOrphans = true,
}) {
  final succeeded = {
    for (final message in history)
      for (final result in message.parts.whereType<ToolResultPart>())
        if (result.name == tool && !result.isError) result.callId,
  };
  for (final message in history) {
    for (final call in message.parts.whereType<ToolCallPart>()) {
      final sent = switch (call.arguments) {
        {'messages': final List<Object?> list} => list,
        {'root': _} && final Map<String, Object?> tree => uiTreeMessages(
          tree,
          target.schemas.catalog,
        ),
        _ => null,
      };
      if (sent != null && call.name == tool && succeeded.contains(call.id)) {
        target.show(
          adoptOrphans ? uiAdoptOrphans(sent, target.schemas.catalog) : sent,
          partial: true,
        );
      }
    }
  }
}
