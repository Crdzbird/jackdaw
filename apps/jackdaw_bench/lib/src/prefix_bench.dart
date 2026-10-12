import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

/// Holds a [turns] long chat and records time to first token per turn, to
/// show that the cached prompt prefix keeps later turns fast.
Future<Map<String, Object>> runPrefixBench(
  LocalModel model, {
  int turns = 20,
}) async {
  final history = <Message>[
    Message.system('You are a helpful assistant. Answer in one sentence.'),
  ];
  final firstToken = <double>[];
  final reused = <int>[];
  final prompt = <int>[];
  for (var turn = 1; turn <= turns; turn++) {
    history.add(Message.user('Tell me fact number $turn about jackdaws.'));
    final events = await model
        .generate(
          ModelRequest(
            messages: List.of(history),
            options: const GenerationOptions(maxOutputTokens: 24),
          ),
        )
        .toList();
    final text = events.whereType<TextDelta>().map((e) => e.text).join();
    history.add(Message.assistant(text));
    final stats = model.stats;
    firstToken.add(stats.firstTokenMs);
    reused.add(stats.reusedTokens);
    prompt.add(stats.promptTokens);
  }
  return {
    'turns': turns,
    'firstTokenTurn2Ms': firstToken[1],
    'firstTokenLastMs': firstToken.last,
    'ratio': firstToken.last / firstToken[1],
    'firstTokenMs': firstToken,
    'reusedTokens': reused,
    'promptTokens': prompt,
  };
}
