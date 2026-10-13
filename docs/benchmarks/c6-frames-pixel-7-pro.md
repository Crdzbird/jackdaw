# Claim C6: UI frames during inference

Date: 2026-10-13. Status: much improved, not yet zero; see "After the fixes".

Claim C6: zero UI-thread frames attributable to inference, measured as
Flutter frame timing during generation against idle.

## Setup

- Pixel 7 Pro, 120 Hz, so the frame budget is 8.3 ms. Profile build.
- Screen: `ChatView` from `jackdaw_flutter` over `LocalModel` with
  Qwen2.5-1.5B-Instruct Q4_K_M, plus a spinning progress indicator so
  frames are produced in both phases.
- Idle: 5 s with the spinner only. Generating: one answer of 200 tokens
  (873 characters), streamed into the chat.
- Frame timings come from `SchedulerBinding.addTimingsCallback`. "Build"
  is UI-thread time; "total" adds raster and queueing.
- Runner: `tool/run_android.sh <device> <model> frames`.

## Results

| Run | Phase | Frames | Build p50 | Build p99 | Build max | Build over budget | Total over budget |
|---|---|---|---|---|---|---|---|
| 4 threads, cool phone | idle | 741 | 1.66 ms | 2.35 ms | 3.0 ms | 0 | 0 |
| 4 threads, cool phone | generating | 1925 | 1.61 ms | 7.13 ms | 16.9 ms | 7 (0.4%) | 62 (3.2%) |
| 4 threads, warm phone | generating | 2342 | 1.86 ms | 8.63 ms | 20.1 ms | 28 (1.2%) | 102 (4.4%) |
| 3 threads, warm phone | generating | 2177 | 1.75 ms | 8.31 ms | 11.9 ms | 21 (1.0%) | 77 (3.5%) |
| 2 threads, warm phone | generating | 2195 | 1.65 ms | 8.39 ms | 13.6 ms | 23 (1.0%) | 112 (5.1%) |

Idle runs never went over budget on the UI thread.

## What this shows

- The median frame is unchanged by inference, so streaming does not
  slow down ordinary frames.
- About 1% of frames during generation take longer than the budget on
  the UI thread, and none do when idle, so C6 as written is not met.
- Fewer inference threads do not remove those frames, so they are not
  mainly CPU contention between llama.cpp and the UI thread.
- Showing the streaming answer as plain text instead of selectable text
  made no measurable difference.

## What the timeline showed

A timeline trace of the generating phase (`tool/run_android.sh <device>
<model> frametrace`, which wraps one answer in `traceAction` and needs
`flutter drive --no-dds`) found no garbage collection in the long frames.
The worst streaming frame spent 5.3 ms in build, 6.1 ms in layout and
3.5 ms in semantics, almost all of it on the streaming text:

- the whole growing answer was laid out again on every update, so the
  cost grew with the length of the answer;
- the whole answer was sent to the semantics tree on every update.

## Fixes in jackdaw_flutter

- The streaming answer is split into paragraphs (`Paragraphs`), so a
  finished paragraph keeps its layout and only the last one is laid out
  again.
- The streaming text is excluded from semantics behind a stable
  "Assistant is answering" label; the full text is announced once it is a
  message. Screen readers no longer re-read every token.
- Finished messages use the same paragraphs under one `SelectionArea`
  instead of `SelectableText`, which keeps text selectable, across
  bubbles too, at a lower layout cost.

## After the fixes

Same setup, warm phone, 4, 3 and 2 inference threads per run:

| Semantics | Build p50 | Build p99 | Build over budget per answer | Frames per answer |
|---|---|---|---|---|
| off | 1.9 to 2.1 ms | 6.0 to 6.6 ms | 1 to 4 | 2500 to 2850 |
| on | 1.2 to 2.0 ms | 4.6 to 6.5 ms | 1 to 2 | 2630 to 3040 |

Before the fixes the same runs had a build p99 of 7.1 to 8.6 ms and 7 to
28 frames over budget per answer. Idle stays at zero. Semantics makes no
measurable difference any more, because the streaming text no longer
reaches the semantics tree.

The frames that remain over budget are the swap at the end of an answer,
when the streamed text becomes a message and the list is laid out again,
and an occasional spike. That is under 0.2 percent of frames, but C6 as
written asks for zero.

## Next steps

1. Keep the streaming bubble's render objects when the answer becomes a
   message, for example by giving both the same key, so the final swap
   does not lay out the whole answer again.
2. If that is not enough, decide whether C6 should be restated, for
   example as "UI build p99 under the frame budget during generation and
   at most one frame over budget per answer".
