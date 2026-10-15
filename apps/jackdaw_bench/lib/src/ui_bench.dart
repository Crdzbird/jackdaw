import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_native/jackdaw_native.dart';

const _options = GenerationOptions(maxOutputTokens: 900);

/// Measures UI answers from [model] for [prompts] in [format], held to
/// the grammar of the basic catalog: how many decode and validate, how
/// many show without an error, with orphans joining the root in the
/// messages format, and how many have no warning either.
Future<Map<String, Object>> runUiBench(
  LocalModel model,
  List<String> prompts, {
  UiFormat format = UiFormat.tree,
}) async {
  final schemas = UiSchemas(basicCatalog);
  final watch = Stopwatch()..start();
  var valid = 0;
  var shown = 0;
  var clean = 0;
  final errors = <String, int>{};
  for (final prompt in prompts) {
    final Object? reply;
    try {
      reply = await generateJson(
        model,
        [Message.user(prompt)],
        format == UiFormat.tree ? schemas.tree : schemas.reply,
        options: _options,
      );
    } on StructuredOutputException {
      continue;
    }
    valid++;
    final surfaces = UiSurfaces(basicCatalog, schemas: schemas);
    final messages = format == UiFormat.tree
        ? uiTreeMessages(reply! as Map<String, Object?>, basicCatalog)
        : uiAdoptOrphans(reply! as List<Object?>, basicCatalog);
    final problems = surfaces.applyAll(messages, replace: true);
    if (problems.every((p) => p.warning)) shown++;
    if (problems.isEmpty) clean++;
    for (final p in problems.where((p) => !p.warning)) {
      final kind = p.message.replaceAllMapped(
        RegExp(r'\b(id|component|surface) \S+'),
        (m) => '${m[1]} X',
      );
      errors[kind] = (errors[kind] ?? 0) + 1;
    }
  }
  return {
    'format': format.name,
    'cases': prompts.length,
    'valid': valid,
    'shown': shown,
    'clean': clean,
    'errors': errors,
    'seconds': watch.elapsed.inSeconds,
  };
}
