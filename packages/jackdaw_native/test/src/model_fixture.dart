import 'dart:io';

/// Path of the GGUF model used by integration tests, or `null` to skip.
final String? testModelPath = Platform.environment['JACKDAW_TEST_MODEL'];

/// Reason shown when integration tests are skipped.
const String noModel = 'set JACKDAW_TEST_MODEL to a GGUF file';
