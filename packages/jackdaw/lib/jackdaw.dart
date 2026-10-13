/// Agent framework for Dart and Flutter.
///
/// Define [Tool]s with codegen-free [Schema]s, pick a [LanguageModel] from a
/// provider package, and run them with an [Agent].
library;

import 'package:jackdaw/jackdaw.dart' show Agent, LanguageModel, Schema, Tool;

export 'src/agent/agent.dart';
export 'src/agent/agent_event.dart';
export 'src/agent/agent_stop_reason.dart';
export 'src/agent/approval_decision.dart';
export 'src/error/provider_exception.dart';
export 'src/error/retry_after.dart';
export 'src/grammar/gbnf_compiler.dart';
export 'src/http/http_transport.dart';
export 'src/http/read_provider_error.dart';
export 'src/message/message.dart';
export 'src/message/part.dart';
export 'src/message/role.dart';
export 'src/model/finish_reason.dart';
export 'src/model/generation_options.dart';
export 'src/model/language_model.dart';
export 'src/model/model_event.dart';
export 'src/model/model_request.dart';
export 'src/model/usage.dart';
export 'src/policy/approval_policy.dart';
export 'src/policy/rule_policy.dart';
export 'src/policy/tool_decision.dart';
export 'src/policy/tool_policy.dart';
export 'src/schema/schema.dart';
export 'src/schema/schema_violation.dart';
export 'src/security/secret.dart';
export 'src/session/in_memory_session_store.dart';
export 'src/session/message_codec.dart';
export 'src/session/record_codec.dart';
export 'src/session/session_record.dart';
export 'src/session/session_store.dart';
export 'src/sse/sse_decoder.dart';
export 'src/sse/sse_event.dart';
export 'src/stream/append_on_done.dart';
export 'src/structured/generate_json.dart';
export 'src/structured/structured_output_exception.dart';
export 'src/tool/tool.dart';
export 'src/tool/tool_context.dart';
export 'src/tool/tool_spec.dart';
