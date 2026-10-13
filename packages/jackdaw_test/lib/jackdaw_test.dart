/// Test utilities for jackdaw.
///
/// Use `ScriptedModel` with `textTurn` and `toolCallTurn` to test agents
/// without network access or API keys, and `languageModelContract` to check
/// that a model implementation behaves like every other one.
library;

export 'src/contract/contract_case.dart';
export 'src/contract/contract_requests.dart';
export 'src/contract/language_model_contract.dart';
export 'src/scripted_model.dart';
export 'src/scripted_turns.dart';
