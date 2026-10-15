import 'package:flutter/widgets.dart';
import 'package:jackdaw/jackdaw.dart';

/// One UI library behind the UI tab: it asks the model for a screen with
/// jackdaw and draws the result.
abstract interface class StudioRenderer {
  /// Asks [model] for a screen as the answer to [messages] and shows it;
  /// [onReply] receives the answer that was shown.
  Future<List<UiProblem>> generate(
    LanguageModel model,
    List<Message> messages,
    void Function(Object? reply) onReply,
  );

  /// The screen built last.
  Widget view();

  /// Frees the library's controller.
  void dispose();
}
