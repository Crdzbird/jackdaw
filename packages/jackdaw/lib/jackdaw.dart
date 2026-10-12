/// Agent framework for Dart and Flutter.
///
/// Define [Tool]s with codegen-free [Schema]s, pick a [LanguageModel] from a
/// provider package, and run them with an [Agent].
library;

import 'package:jackdaw/jackdaw.dart' show Agent, LanguageModel, Schema, Tool;

export 'src/agent/agent.dart';
export 'src/agent/agent_event.dart';
export 'src/agent/agent_stop_reason.dart';
export 'src/error/provider_exception.dart';
export 'src/error/retry_after.dart';
export 'src/grammar/gbnf_compiler.dart';
export 'src/message/message.dart';
export 'src/message/part.dart';
export 'src/message/role.dart';
export 'src/model/finish_reason.dart';
export 'src/model/generation_options.dart';
export 'src/model/language_model.dart';
export 'src/model/model_event.dart';
export 'src/model/model_request.dart';
export 'src/model/usage.dart';
export 'src/schema/schema.dart';
export 'src/schema/schema_violation.dart';
export 'src/security/secret.dart';
export 'src/sse/sse_decoder.dart';
export 'src/sse/sse_event.dart';
export 'src/structured/generate_json.dart';
export 'src/structured/structured_output_exception.dart';
export 'src/tool/tool.dart';
export 'src/tool/tool_spec.dart';
