# jackdaw_cli

Command line tools for `jackdaw`.

```text
dart run jackdaw_cli:jackdaw <command> [arguments]

  inspect <session.jsonl>             timeline of a session journal
  trace <trace.jsonl>                 spans written by a JsonlTracer
  grammar <schema.json>               GBNF grammar for a JSON Schema
  validate <schema.json> <value.json> check a value against a schema
```

- `inspect` reads a journal written by `FileSessionStore` and shows every
  message, tool call, approval and result in order, then what the session
  is waiting for: an approval, unfinished tool calls, the model, or
  nothing because it answered.
- `trace` reads the file of a `JsonlTracer` from `package:jackdaw/io.dart`
  and lists each span with its duration, token counts and error, then the
  totals.
- `grammar` prints the grammar local models are constrained with for a
  schema, which helps when structured output looks wrong.
- `validate` checks JSON the way tool arguments and structured output are
  checked.

Journals and traces hold conversations and tool data, so keep them out of
shared places.
