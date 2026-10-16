# Performance analysis: where a local UI turn spends its time

Date: 2026-10-16. Device: Pixel 7 Pro (Tensor G2: 2 Cortex-X1 at 2.85 GHz,
2 A78 at 2.35 GHz, 4 A55 at 1.8 GHz, dot product but no int8 matrix
multiply), Qwen2.5-1.5B-Instruct Q4_K_M, CPU backend, 4 threads.

This page follows one generative UI request from the tap to the drawn
screen, measures each stage, and records what was changed, what was tried
and dropped, and what is left.

## Tools

- `native/bench/jackdaw_speed.cpp` (`-DJACKDAW_BUILD_BENCH=ON`): drives
  the jackdaw C API on the device over adb, so the core is measured
  without Flutter. It reports prompt and generation speed, grammar parse
  time and the generated text.
- llama.cpp's `llama-bench`, built from the same pinned source with the
  same flags (`armv8.2-a+dotprod+fp16`), as the reference for what the
  hardware can do.
- On-device integration probes for the UI isolate, saved state and frames
  (`integration_test/ui_compare_bench.dart` and others).

The phone throttles within a minute of sustained work: generation fell
from 12.5 to 8.9 tokens/s across three runs, and `llama-bench` from 19.8
to 15.6 tokens/s after another run. Every comparison below alternates
the variants and lets the phone cool between them.

## Where the time goes

| Stage | Where it runs | Before | Now |
|---|---|---|---|
| Compile the UI grammar | UI isolate | 9.7 ms per request | once per schema, warmed while the model loads |
| Parse the grammar | native worker | 14.5 ms (179 KB) | 2.9 ms (28 KB) |
| Apply the chat template | UI isolate, synchronous FFI | 1.1 to 2.8 ms | native worker |
| Count tokens for the context budget | UI isolate, synchronous FFI | 3.7 ms for a 1,226 token prompt, every turn | once per message |
| Process the 1,247 token prompt | native threads | 13 to 26 s | 0.39 s to the first token after `loadState` |
| Generate a UI answer | native threads | 225 tokens at 13 tokens/s | about 107 tokens at 20 tokens/s |
| Validate and apply the answer | UI isolate | 0.1 ms and 1.7 ms | same |
| Build the first frame of a 40 component screen | UI isolate | 55 to 70 ms | see C14 |

The prompt dominates the first request: the UI guide alone is about 1,200
tokens, and this CPU processes 57 to 59 tokens/s at that length whatever
the settings. After that, generation dominates.

## Changes that paid off

### A persistent thread pool (C++)

Without a pool attached to the context, ggml creates and joins a
throwaway pool for every graph it computes, which is once per generated
token. Prompt processing barely noticed; generation did. Each session
and embedder now keeps one pool for its whole life.

| Same phone, alternating | Generation, tokens/s |
|---|---|
| Before | 13.9, 12.3, 13.9, 12.8 |
| After | 17.6, 15.5, 16.7, 15.4 |

Inside the app, with cool-downs between runs, generation now measures
20.3 to 20.5 tokens/s, against 13.0 on 2026-10-12 and 20.8 for
`llama-bench` on the same phone: the core is at parity with llama.cpp.

`NativeSessionOptions.generateThreads` sets the generation threads apart
from prompt processing. Two threads generate at 19.3 to 19.6 tokens/s,
5% slower than four, which an app may trade for free cores.

### Saving and loading the processed prompt (C++ and Dart)

`jackdaw_session_save` and `jackdaw_session_load` write and read the
tokens a session has processed and their KV cache, and
`LocalModel.saveState` and `loadState` call them on a background
isolate. A prompt that starts with the saved tokens only processes the
rest.

| UI build on the Pixel | Cold | After `loadState` |
|---|---|---|
| Time to first token | 13.3 s | 0.39 s |
| Whole build | 26.8 s | 14.7 s |
| Prompt tokens processed | 1,246 | 17 |

Saving took 34 ms and loading 23 ms, for a 40.5 MB file. A file from
another model is refused and leaves an empty cache.

### Smaller, cached grammars (Dart)

The compiler shared rules only when the same schema object appeared
twice, while the UI schemas build many equal objects: one per tree
level, per component and per value type. Rules with the same body are
now shared too, which cut the tree grammar from 179 KB to 28 KB. The
compiled grammar is kept per schema object, and tool call grammars are
kept for the last 16 combinations of tools, so a repeated turn costs a
lookup instead of 3.6 ms on the Mac and about 10 ms on the phone.

### Compact JSON (Dart)

The grammar no longer allows whitespace between JSON tokens. The same
answer is 225 tokens pretty printed, 155 with single spaces and 107
compact. On 20 UI cases (Mac CPU, same native code):

| Whitespace allowed | Valid | Time |
|---|---|---|
| Up to four characters | 11 / 20 | 220 s |
| One space | 17 / 20 | 119 s |
| None | 19 / 20 | 63 s |

The failures with whitespace were answers that ran out of tokens before
the JSON closed. Structured output stayed at 200/200 (C1). Tool calls
first fell to 75% right arguments, because the wrapper around the
arguments was still spaced; written compact throughout they are back at
96% (C2).

### Less work on the UI isolate at send time (C++ and Dart)

- `jackdaw_session_generate_chat` renders the chat template on the
  session's worker, and `LocalModel.generate` uses it when the library
  has it, so sending no longer renders the prompt on the UI isolate. A
  library without it, such as the published 0.1.0-dev.5, still works:
  the Dart side probes for it once and falls back.
- `TokenCounter.fromText` remembers each message's count, so the budget
  tokenizes only new messages instead of the whole history every turn.
- The demo compiles the UI grammar while the model loads.

In the C6 run that followed, the frame at the moment of sending took
8.8 ms against the 8.3 ms budget, and 2 of 1,075 frames during
generation went over.

## Tried and dropped

| Idea | Result |
|---|---|
| Pin the 4 threads to the fast cores (`0xF0`, strict) | Slower: 82 against 120 prompt tokens/s |
| 6 or 8 threads | Collapses: 4.7 tokens/s generation at 8 threads |
| Flash attention on or off | No difference at 1,248 tokens |
| 8 bit KV cache | Slower: 39 against 57 prompt tokens/s |
| Micro-batch 256 or 1,024 | No difference |
| Read greedy tokens straight from the logits | No measurable gain |
| Speculative decoding by prompt lookup | 12% of drafted tokens kept on UI answers; generation fell from 46 to 26 tokens/s on the Mac, because every drafted position computes logits over the 151,936 token vocabulary |
| Compile the first grammar on another isolate | Not done: `Isolate.run` copies the schema graph on the calling isolate, which would eat much of the 10 ms; compiling while the model loads avoids both |

The native changes ship in the native-v0.1.0-dev.6 prebuilt libraries,
which the hook pins.

## Open

- The frame at the moment of sending is 0.5 ms over budget.
- A vague request such as "a sign-up form for a coffee shop" can make the
  1.5B model list fields until the token limit, so the JSON never closes.
- The first frame of a new screen; see C14.
- A Q4_0 model would let llama.cpp use its KleidiAI kernels; that needs a
  new model download.
