import 'dart:convert';

import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/message/role.dart';
import 'package:jackdaw/src/ui/agent/ui_action.dart';

const String _marker = 'UI action: ';

/// [action] as the user message that tells the agent what happened on a
/// surface, with the A2UI `action` message and, when the surface sends it,
/// the data model.
Message uiActionMessage(UiAction action) => Message.user(
  [
    ?action.userMessage,
    '$_marker${jsonEncode(action.toJson())}',
    if (action.dataModel != null)
      'Data model of ${action.surfaceId}: ${jsonEncode(action.dataModel)}',
  ].join('\n'),
);

/// What a chat shows for [message] when it reports a UI action: the
/// action's user message, empty when it has none, or `null` when
/// [message] is not a UI action.
String? uiActionCaption(Message message) {
  if (message.role != Role.user) return null;
  final text = message.text;
  final at = text.startsWith('$_marker{') ? 0 : text.indexOf('\n$_marker{');
  if (at < 0) return null;
  return text.substring(0, at).trim();
}
