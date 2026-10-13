@TestOn('browser')
library;

import 'package:jackdaw_test/jackdaw_test.dart';
import 'package:jackdaw_web/jackdaw_web.dart';
import 'package:test/test.dart';

import 'web_harness.dart';

const _call =
    '<tool_call>\n{"name": "ping", "arguments": {"text": "hello"}}\n'
    '</tool_call>';

/// Claim C8: the web model passes the same contract as the native one.
void main() {
  late WebLocalModel model;

  setUpAll(() async => model = await openFake());

  languageModelContract(
    () => model,
    prepare: (c) async => script(switch (c) {
      ContractCase.text => [
        chunk({'content': 'Hello'}, finish: 'stop'),
      ],
      ContractCase.limit => [
        chunk({'content': 'One two'}, finish: 'length'),
        {
          'choices': <Object?>[],
          'usage': {'prompt_tokens': 9, 'completion_tokens': 3},
        },
      ],
      ContractCase.schema => [
        chunk({'content': '{"answer": "yes", "sure": true}'}, finish: 'stop'),
      ],
      ContractCase.toolCall => [
        chunk({'content': _call}, finish: 'stop'),
      ],
      ContractCase.cancel => [
        for (var i = 0; i < 20; i++) chunk({'content': 'word '}),
      ],
    }),
  );
}
