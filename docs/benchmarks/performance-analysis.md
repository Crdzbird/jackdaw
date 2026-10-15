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
| Compile the UI grammar | UI isolate | 9.7 ms per request | once per schema, then cached |
| Parse the grammar | native worker | 14.5 ms (179 KB) | 2.9 ms (28 KB) |
| Apply the chat template | UI isolate, synchronous FFI | 1.1 to 2.8 ms | same |
| Count tokens for the context budget | UI isolate, synchronous FFI | 3.7 ms for a 1,226 token prompt | same |
| Process the 1,247 token prompt | native threads | 13 to 26 s | 0.39 s to the first token after `loadState` |
| Generate about 160 tokens with the grammar | native threads | 9 to 13 tokens/s | about 22% faster |
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

`llama-bench` reaches 19.8 tokens/s on a cool phone, so the core is now
within the throttling noise of what llama.cpp itself does.

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

## Open

- Whitespace: a pretty-printed UI answer is 225 tokens, the same answer
  with single spaces 155 and compact 107. The grammar allows up to four
  whitespace characters between tokens, and the model uses them. The
  effect of restricting it on validity is being measured.
- Two generation threads are as fast as four on this phone (20.5 against
  20.8 tokens/s), because generation is bound by memory. Fewer threads
  would leave cores to Flutter and run cooler.
- Work at the moment of sending, on the UI isolate: the first grammar
  compile, the chat template and token counting. This is the frame C6
  still loses when a message is sent.
- A vague request such as "a sign-up form for a coffee shop" can make the
  1.5B model list fields until the token limit, so the JSON never closes.
- The first frame of a new screen; see C14.
