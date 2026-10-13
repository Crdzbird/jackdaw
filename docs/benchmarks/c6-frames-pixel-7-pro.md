# Claim C6: UI frames during inference

Date: 2026-10-13. Status: not met yet.

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

## Next steps

1. Record a timeline trace of the generating phase to find what runs in
   the long frames; the suspects are garbage collection from per-token
   allocations on the UI isolate and the rebuild when the answer becomes
   a message.
2. If per-token work on the UI isolate is the cause, run the native
   session's event handling in a background isolate and send the UI one
   merged text update per frame.
