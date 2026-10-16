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
| Applying the screen's messages | 0.19 ms | 0.35 ms |
| Screen received to first frame | 7.9 ms | 10.0 ms |
| Screen fully drawn | 8.4 ms | 10.5 ms |
| Slowest build while creating | 7.3 ms | 8.7 ms |
| Raster while creating, p99 | 4.1 ms | 5.0 ms |
| Build in the whole creation window | 81.1 ms | 59.9 ms |
| Applying one data write | 0.077 ms | 0.085 ms |
| Frame build during writes, p50 | 4.6 ms | 4.5 ms |
| Frame build during writes, p99 | 11.0 ms | 11.4 ms |
| Frame build during writes, max | 13.9 ms | 13.2 ms |
| Raster during writes, p99 | 4.6 ms | 5.8 ms |
| Builds over the budget during writes | 4.5 | 2.5 |

jackdaw_flutter applies and draws a new screen faster, and keeps that
frame within the budget; the two are level while data is written.
Neither side keeps every write frame within 8.3 ms, so C14 is not met
yet.

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
