import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/message/part.dart';
import 'package:jackdaw/src/ui/agent/ui_adopt_orphans.dart';
import 'package:jackdaw/src/ui/surface/ui_surfaces.dart';

/// Rebuilds [surfaces] from [history], such as a restored session: every
/// successful call of the tool named [tool] is applied again in order, as
/// `uiTool` applied it.
///
/// What the user entered is not in the transcript, so inputs come back
/// with the values the agent last sent.
void uiReplay(
  UiSurfaces surfaces,
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
      if (call.arguments case {'messages': final List<Object?> sent}
          when call.name == tool && succeeded.contains(call.id)) {
        surfaces.applyAll(
          adoptOrphans ? uiAdoptOrphans(sent, surfaces.catalog) : sent,
          replace: true,
        );
      }
    }
  }
}
