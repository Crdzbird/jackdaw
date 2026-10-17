# jackdaw_test

Test utilities for `jackdaw`.

`ScriptedModel` replays prepared turns and records every request, so agents
can be tested without network access or API keys.

```dart
final model = ScriptedModel([
  toolCallTurn([ToolCallPart(id: '1', name: 'add', arguments: {'a': 1})]),
  textTurn(['done']),
]);
```
