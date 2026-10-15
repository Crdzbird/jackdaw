import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_flutter/src/ui/ui_surface_controller.dart';

/// One item of the transcript as a chat shows it: the index of its
/// message, the message, the text of its bubble, and the surfaces it
/// shows.
typedef ChatEntry = ({
  int index,
  Message message,
  String text,
  List<String> surfaces,
});

/// The entries a chat shows for [messages], newest first: user and
/// assistant text, the caption of a UI action that has one, and each tool
/// result that last showed a surface still in [ui].
List<ChatEntry> chatEntries(List<Message> messages, UiSurfaceController? ui) {
  final latest = <String, int>{
    for (final (index, message) in messages.indexed)
      for (final result in message.parts.whereType<ToolResultPart>())
        if (result.output case {'shown': final List<Object?> shown})
          for (final id in shown.whereType<String>()) id: index,
  };
  final live = ui?.surfaces.surfaces ?? const {};
  ChatEntry? entry(int index, Message message) {
    final surfaces = [
      if (message.role == Role.tool)
        for (final MapEntry(key: id, value: at) in latest.entries)
          if (at == index && live.containsKey(id)) id,
    ];
    final text = message.role == Role.user || message.role == Role.assistant
        ? (uiActionCaption(message) ?? message.text).trim()
        : '';
    if (surfaces.isEmpty && text.isEmpty) return null;
    return (index: index, message: message, text: text, surfaces: surfaces);
  }

  return [
    for (final (index, message) in messages.indexed.toList().reversed)
      ?entry(index, message),
  ];
}
