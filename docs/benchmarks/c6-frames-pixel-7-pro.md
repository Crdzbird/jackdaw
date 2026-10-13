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

## Final state (cool phone, warm-up turn first)

Later changes: every bubble is keyed by its place in the transcript and
keeps its layout when a turn starts, the streamed text keeps its layout
when it becomes a message, and the composer stays editable during a turn.
The benchmark now runs one warm-up turn first, as in a chat already in
use, because the very first text drawn pays for shaping glyphs once.

| Phase | Frames | Build p50 | Build p99 | Builds over the 8.3 ms budget |
|---|---|---|---|---|
| Idle | 754 | | 3.1 ms | 0 |
| Generating (second turn) | 1155 | 1.8 ms | 5.8 ms | 2 |

The two frames over budget:

- 12.3 ms at 24 ms into the turn: the frame that draws the user's own
  message and the new streaming bubble, the response to tapping send. A
  trace shows no single cause; the time is spread over text layout,
  the list and the composer.
- 9.0 ms at 7.3 s: one streaming frame, 0.7 ms over.

At 60 Hz, where the budget is 16.7 ms, both would fit.

## Decision needed

C6 as written asks for zero frames attributable to inference. Streaming
itself is within budget in all but one frame in about 1150; the frame
that renders a sent message is UI work in response to a tap. Options:

1. Sign off C6 restated as "during generation, UI build p99 stays under
   the frame budget and at most one streaming frame per answer exceeds
   it, at 120 Hz on the reference device".
2. Keep working on the send frame, for example by drawing the user's
   message one frame before the streaming bubble appears.

