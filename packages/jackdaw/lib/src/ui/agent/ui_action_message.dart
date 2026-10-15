import 'dart:convert';

import 'package:jackdaw/src/message/message.dart';
import 'package:jackdaw/src/ui/agent/ui_action.dart';

/// [action] as the user message that tells the agent what happened on a
/// surface, with the A2UI `action` message and, when the surface sends it,
/// the data model.
Message uiActionMessage(UiAction action) => Message.user(
  [
    ?action.userMessage,
    'UI action: ${jsonEncode(action.toJson())}',
    if (action.dataModel != null)
      'Data model of ${action.surfaceId}: ${jsonEncode(action.dataModel)}',
  ].join('\n'),
);
