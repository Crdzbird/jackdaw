# C14: drawing agent UI, jackdaw_flutter against genui

Claim C14 says applying UI loses no frame on the reference device. This
page also compares jackdaw_flutter with Flutter's official genui package
on the same screens, since an app can draw jackdaw's UI with either.

## Method

`integration_test/ui_compare_bench.dart`, run with `BENCH=uicompare` in
profile mode. No model is involved: both sides get the same A2UI messages.

- The screen is a column of 40 components: texts, text fields, checkboxes,
  sliders and dividers, all bound to the data model. 40 is the most one
  jackdaw message may carry.
- jackdaw_flutter gets the A2UI v1.0 messages through
  `UiSurfaceController.applyAll` and draws them with `UiSurfaceView`.
- genui 0.10.4 gets the same messages lowered to A2UI v0.9 by
  `uiLowerToV09`, done before the clock starts, through its
  `SurfaceController.handleMessage`, and draws them with its `Surface`.
- After the screen is drawn, 120 data writes follow, one per frame.
- A spinner keeps frames coming. The sides take turns in alternating
  order: a warm-up round, then five reported rounds each. The run is
  repeated, so each number below is the median of ten rounds.
- Each round checks that the screen was really drawn, down to its last
  text, field and checkbox, before its numbers count.
- Frame timings arrive in batches, so each frame is assigned to the
  creation or the write phase by the time its build started, not by when
  its timing arrived.
- Before the screen arrives, the UI thread is kept busy for 200 ms, as
  it is at the end of a generation; see "The clock speed" below.

## Results on the reference device

Pixel 7 Pro, Android, 120 Hz, so the frame budget is 8.3 ms.

| Median of 10 rounds | jackdaw_flutter | genui |
|---|---|---|
| Applying the screen's messages | 0.19 ms | 0.43 ms |
| Screen received to first frame | 8.8 ms | 12.6 ms |
| Screen fully drawn | 9.3 ms | 13.9 ms |
| Slowest build while creating | 7.8 ms | 10.5 ms |
| Raster while creating, p99 | 4.3 ms | 5.1 ms |
| Applying one data write | 0.100 ms | 0.085 ms |
| Frame build during writes, p50 | 3.5 ms | 4.9 ms |
| Frame build during writes, p99 | 6.1 ms | 11.4 ms |
| Frame build during writes, max | 7.4 ms | 13.9 ms |
| Raster during writes, p99 | 4.6 ms | 5.7 ms |
| Builds over the budget during writes | 0 | 6 |

Over all ten rounds, jackdaw_flutter went over the 8.3 ms budget four
times: twice while creating (9.7 and 9.8 ms) and twice during writes
(8.9 and 10.4 ms). genui went over once in every creation and 94 times
during writes. Traces put the slow frames that remain down to garbage
collection pauses of 7 to 18 ms, so C14 is close but not met.

The table is from 2026-10-16, after each data-bound component got a
layer of its own; see "Paint during writes".

The build in the whole creation window, which also covers the half
second of spinner frames after the screen, is higher for jackdaw_flutter,
but not because it does more. A trace of six rounds per side found the
same work in every idle frame on both sides: the spinner's
AnimatedBuilder and CustomPaint and the same scroll and semantics
layers, and nothing in either surface rebuilt or repainted after it was
drawn. The creation frame and the five after it took 7.7 and 3.1 ms
with jackdaw_flutter against 13.6 and 4.8 ms with genui. The rest of the
window cost 1.43 ms per frame against 1.06 ms for the same work: having
finished sooner, the CPU clocks down sooner, and by 200 ms after the
screen a spinner frame takes 1.43 ms against 0.81 ms. jackdaw_flutter
also draws 60 frames in the window against 55, because genui's longer
creation frame skips vsyncs. The window total measures the clock and the
skipped frames, so the table above leans on the creation frame itself.

## Paint during writes

A trace of 120 writes per side found that every frame over budget,
apart from those with a garbage collection, spent 5 to 8 ms in paint,
against under 1 ms in build and about 1 ms in layout, on both sides.
A write changes one text, but the nearest repaint boundary was the whole
surface, so all 40 components were painted again. Each component that
reads data now sits on a repaint boundary of its own, and components
that cannot change on a write do not, to keep the layer count down.
Paint during writes fell to 1.3 ms at the median against 2.8 ms for
genui, and over-budget frames during writes from 17 in four traced
rounds to none.

## The clock speed

Earlier runs started each screen after 600 ms of idle frames, and found
genui 4 to 10 ms faster at creating it. Tracing a screen of 8 text
fields showed why. Each field has the same 52 elements and 24 render
objects on both sides, and in jackdaw_flutter's slow rounds build,
layout and paint were all about 2.4 times longer at once, while its fast
rounds took 17.7 ms against genui's best of 25.0 ms. Every phase growing
together is what a slower clock does, not more work. After the idle
wait the cores clock down; jackdaw_flutter applies the screen in about
2 ms and draws at once, on a cold core, while genui's longer apply warms
it first. With the UI thread kept busy for 200 ms before the screen
arrives, the 8 fields took 5.4 ms with jackdaw_flutter and 6.2 ms with
genui from apply to the end of the frame. A screen in an app arrives at
the end of a generation, with the cores busy, so the warm numbers are
the ones that apply.

## Results on the emulator

Android emulator, Pixel 8 Pro image, API 28, arm64, on an Apple Silicon
Mac. The emulator's GPU makes raster times meaningless, so they are left
out. These runs predate the per-frame timestamps.

| Median of 10 rounds | jackdaw_flutter | genui |
|---|---|---|
| Screen received to first frame | 30.9 ms | 39.2 ms |
| Applying the screen's messages | 0.45 ms | 0.81 ms |
| Slowest build while creating | 23.6 ms | 28.5 ms |
| Applying one data write | 0.070 ms | 0.077 ms |
| Frame build during writes, p50 | 3.2 ms | 3.6 ms |
| Frame build during writes, p99 | 10.2 ms | 10.1 ms |

On the host, in a warm loop, applying the screen takes 62 us in jackdaw
and 342 us in genui, and one write 1.5 us and 2.0 us.

## What changed to get here

The first comparison had jackdaw_flutter far behind: 226 ms to the first
frame against 14 ms on the emulator, and update builds of 149 ms at p99,
because every data write redrew the whole surface.

- Each component is now a widget of its own that watches the data paths
  its props read, `@path` bindings in calls and templates included. A
  write reaches only the watchers of its path, the paths above it and the
  root, by lookup. The whole surface is redrawn only when components
  change.
- Columns no longer build their children inside a LayoutBuilder, which
  moved all of their building into the layout phase. `UiStretch` gives
  each child the full width when it is bounded, during layout. On the
  Pixel this cut the creation frame's layout from 31 ms to 9 ms and its
  paint from 15 ms to 6 ms.
- Each surface sits on its own repaint boundary, so animations around it
  do not repaint it.
- Validation checks values with `Schema.accepts`, which builds no
  violation paths, and only runs `validate` when a value fails.
- A union schema builds each tagged variant once, not once per value.
- `applyAll` validates each message once, and checks the component tree
  only when components changed, not after data writes.
- The catalog looks components up by name in a map, and surfaces share
  one set of schemas per catalog.
