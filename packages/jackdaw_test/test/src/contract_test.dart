import 'package:jackdaw/jackdaw.dart';
import 'package:jackdaw_test/jackdaw_test.dart';

/// The scripted model passes the contract it offers to other models.
void main() {
  var model = ScriptedModel(const []);
  languageModelContract(
    () => model,
    prepare: (c) async {
      model = ScriptedModel([
        switch (c) {
          ContractCase.text => textTurn(['Hel', 'lo']),
          ContractCase.limit => const [
            TextDelta('One two'),
            FinishEvent(
              reason: FinishReason.length,
              usage: Usage(outputTokens: 3),
            ),
          ],
          ContractCase.schema => textTurn(['{"answer": "yes", "sure": true}']),
          ContractCase.toolCall => toolCallTurn(const [
            ToolCallPart(id: 'c1', name: 'ping', arguments: {'text': 'hello'}),
          ]),
          ContractCase.cancel => textTurn(['Once ', 'upon ', 'a time']),
        },
      ]);
    },
  );
}
