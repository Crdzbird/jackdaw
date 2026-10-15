import 'dart:io';

/// A GGUF file to load instead of the default model, for development and
/// the benchmarks. When empty, the default model is downloaded.
const String modelPath = String.fromEnvironment('JACKDAW_MODEL');

/// Where the demo keeps the downloaded model and the chat journals.
const String dataFolder = String.fromEnvironment(
  'JACKDAW_DATA',
  defaultValue: '/data/user/0/dev.crdzbird.jackdaw_bench/files',
);

/// Where the demo keeps the processed UI prompt, next to the chat
/// journals in [sessions].
File uiStateFile(String sessions) =>
    File('${Directory(sessions).parent.path}/ui_state.bin');

/// Another address for the default model, such as a local mirror; its
/// size and hash must still match.
const String modelUrl = String.fromEnvironment('JACKDAW_MODEL_URL');
