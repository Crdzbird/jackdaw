import 'package:jackdaw/jackdaw.dart';

/// The user's [text] as the next request of the UI tab. After a first
/// screen it asks for that screen again with the change, which small
/// models otherwise tend to answer with the old screen.
Message studioRequest(List<Message> history, String text) =>
    Message.user(switch (history) {
      [] => text,
      _ =>
        'Change that screen: $text. Send the whole screen again with '
            'the change.',
    });
