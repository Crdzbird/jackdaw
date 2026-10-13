# Claim C9: the agent loop runs offline

Date: 2026-10-13. Status: met on macOS; not yet run in CI.

Claim C9: the full agent loop (tools, retrieval, schema validation) runs
with networking disabled.

## Check

`packages/jackdaw_native/tool/offline_check.dart` runs, on one local GGUF
model:

1. a retriever over three made-up notes, embedded by `NativeEmbedder`
   and stored in `NativeVectorIndex`;
2. an agent with `retrievalTool`, asked about one of the notes; it must
   call the tool, get the right note back and answer from it;
3. `generateJson` with an object schema, validated offline.

The facts are invented ("the zorblin eats blue moss"), so the right answer
can only come from retrieval.

`tool/check_offline.sh <model.gguf>` compiles the check with
`dart build cli`, which bundles `libjackdaw`, and runs the bundle with
networking denied by the operating system: `sandbox-exec` with
`(deny network*)` on macOS, a fresh network namespace through `unshare` on
Linux. The same check runs as a normal test,
`test/src/offline_loop_test.dart`, with every Dart HTTP client blocked.

The bundle is used because `dart test` itself contacts pub.dev for
package advisories before running and stops when it cannot reach it.

## Result

| Platform | Model | Result |
|---|---|---|
| macOS (Apple silicon), `sandbox-exec` denying all network access | Qwen2.5-1.5B-Instruct Q4_K_M | ok: tool called, note retrieved, answer used it, JSON valid |

`curl https://pub.dev` fails inside the same sandbox, confirming the
network is really off.

## Notes

- With a 1.5B model the question has to ask for a search ("Search the
  documents: ..."); asked plainly, the model sometimes answered without
  calling the tool and claimed the note was missing.
- A CI job needs a GGUF model on the runner. That is a download per run
  (or a cached one), so it waits for a decision.
