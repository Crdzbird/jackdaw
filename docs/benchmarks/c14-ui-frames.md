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
  repeated four times, so each number below is the median of twenty
  rounds.
- Each round checks that the screen was really drawn, down to its last
  text, field and checkbox, before its numbers count.
- Frame timings arrive in batches, so each frame is assigned to the
  creation or the write phase by the time its build started, not by when
  its timing arrived.
- Before the screen arrives, the UI thread is kept busy for 200 ms, as
  it is at the end of a generation; see "The clock speed" below.

## Results on the reference device

Pixel 7 Pro, Android, 120 Hz, so the frame budget is 8.3 ms.

| Median of 20 rounds | jackdaw_flutter | genui |
|---|---|---|
| Applying the screen's messages | 0.19 ms | 0.38 ms |
| Screen received to first frame | 8.7 ms | 11.2 ms |
| Screen fully drawn | 9.2 ms | 11.7 ms |
| Slowest build while creating | 8.0 ms | 8.9 ms |
| Raster while creating, p99 | 4.5 ms | 4.9 ms |
| Applying one data write | 0.104 ms | 0.085 ms |
| Frame build during writes, p50 | 3.1 ms | 4.8 ms |
| Frame build during writes, p99 | 5.0 ms | 10.9 ms |
| Frame build during writes, max | 5.8 ms | 13.6 ms |
| Raster during writes, p99 | 4.8 ms | 5.6 ms |
| Builds over the budget during writes | 0 | 4.5 |

Over all twenty rounds, jackdaw_flutter went over the 8.3 ms budget ten
times: seven times while creating (8.6 to 12.1 ms) and three times
during writes (11.8, 13.5 and 19.1 ms). genui went over in 19 of the 20
creations and 105 times during writes. Traces put the slow write frames
down to garbage collection pauses, so C14 is close but not met; see
"Garbage collection".

The table is from 2026-10-16, after every component got a layer of its
own; see "Paint during writes" and "Native objects per frame".

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
reads data now sits on a repaint boundary of its own. Paint during
writes fell to 1.3 ms at the median against 2.8 ms for genui, and
over-budget frames during writes from 17 in four traced rounds to none.
At first, components that read no data got no boundary, to keep the
layer count down; "Native objects per frame" shows why they now get one
too.

## Garbage collection

Traces of creation and 600 writes per side, with the VM's own
collection events, show why jackdaw_flutter's few slow frames are longer
than genui's many. These traces predate the layer on every component.

| During writes | jackdaw_flutter | genui |
|---|---|---|
| Young collections per second | 0.38 | 1.21 |
| Young collection time per second | 5.3 ms | 5.8 ms |
| Usual young collection | 10 to 13 ms | 4 to 5 ms |
| Objects surviving one | 18 to 44 KB | 63 to 80 KB |

- Nothing piles up. Across 600 writes the live heap grew by the same
  amount on both sides, and that growth was the probe's own records.
- Survivors do not set the pause. Each round has one collection that
  copies the new screen, about 1.4 MB with jackdaw_flutter and 1.5 MB
  with genui. It took 2.3 to 3.7 ms when it came 0.2 s after the screen,
  and the collections with only 20 KB to copy took 12 to 19 ms.
- In the slow collections, 9.9 of 11.1 ms and 10.9 of 12.6 ms went to
  `MournWeakHandles`: the VM running the finalizers of `dart:ui`'s
  native objects, such as pictures, canvases, engine layers and
  paragraphs, inside the pause. Every frame leaves some, on both sides.
- jackdaw_flutter's writes allocate so little that its young generation
  fills only every 2 to 3 seconds, and each collection then finalizes 2
  to 3 seconds of frames at once. genui's fills about every 0.8 seconds.
  The total is the same; jackdaw_flutter pays it in fewer, longer
  pauses.
- Adding a collection before the writes, to clear the messages the
  bench prepares, changed nothing: 8.1 against 7.6 ms at the median.

None of this is work jackdaw_flutter could drop: the finalizers belong to
the engine, and allocating more on purpose to collect more often would
trade the pauses for more work in every frame. Fewer native objects per
frame would shorten the pauses, but the finalizing cost is about 35 us a
frame on both sides, although genui paints the whole surface again on
every write and jackdaw_flutter one component. Most of it seems to come
with every frame, from the spinner and the scene, not from either
surface.

## Native objects per frame

The VM's allocation tracing, turned on for every native class of
`dart:ui`, counts each picture, recorder, canvas, path, paragraph and
engine layer a frame leaves for the finalizers, with the stack that made
it. Over 60 frames of each kind:

| Native objects per frame | Pictures | Engine layers | Paths | All |
|---|---|---|---|---|
| The spinner alone | 1 | 7 | 1 | 13 |
| jackdaw_flutter, idle | 1 | 7 | 1 | 13 |
| jackdaw_flutter, a write, before | 11 | 11 | 8 | 56 |
| jackdaw_flutter, a write, now | 4 | 12 | 1 | 29 |
| genui, idle | 1 | 15 | 1 | 21 |
| genui, a write | 26 | 33 | 16 | 131 |

A write changes one text, which could change its size, so Flutter lays
out everything up to the nearest relayout boundary: the surface's
column, the scroll view and, in this screen, the Scaffold. Flutter
repaints every object it lays out. The column's repaint drew the seven
dividers again, each in a picture of its own between the layers of its
bound neighbours, with a path for its border: 28 of the 43 objects a
write added. With a layer on every component, the column's repaint
only places layers that are already drawn. What is left is the changed
text's picture and paragraph and the Scaffold's own repaint, which genui
pays too.

The finalizers' share of the young collections fell from about 10 ms to
0.6 to 1.8 ms, 3.5 us a frame against 38.9 us for genui. The pauses that
remain, 6 to 10 ms, are now the copy of the new screen's objects, which
comes when the young generation first fills, during the writes. The
same copy took 2.3 to 3.7 ms when it came right after the screen was
drawn, on a busier and faster core; see "Garbage collection".

## Memory per component

The pauses that remain copy the new screen's objects, so their size
matters. A class by class diff of the live heap before and after each
screen was applied, with a full collection before each count and the
probe's own records (about 190 KB) taken out by an empty run, gives
what one component keeps alive on the Pixel:

| Per component | jackdaw_flutter | genui |
|---|---|---|
| Mixed bench screen | 35.5 KB, 803 objects | 40.4 KB, 899 objects |
| Text | 7.8 KB | 15.6 KB |
| TextField | 75.9 KB | 77.7 KB |
| CheckBox | 51.5 KB | 55.1 KB |
| Slider | 27.2 KB | 35.3 KB |
| Divider | 12.2 KB | 9.0 KB |

- Almost all of it is Flutter's own widgets. A Material text field
  keeps about 76 KB on either side, with 156 closures, 8 animation
  controllers and 59 observer lists, and the eight fields hold 600 of
  the mixed screen's 1,385 KB.
- jackdaw's own objects, the component, its node, its widget and state
  and the stretch wrapper, take about 0.3 KB per component.
- jackdaw_flutter adds two render objects to each component, its layer
  and the stretch wrapper, which is why a Divider is 3.2 KB heavier.
  Folding the layer into the wrapper would save about 0.9 KB per
  component, under 3% of the screen.
- Every render object keeps semantics state even with semantics off:
  `RenderObject.attach` reads its semantics configuration before
  anything checks for a semantics owner, which builds a
  `SemanticsConfiguration`, five `AttributedString`s, four lists and a
  map, about 560 bytes. No `SemanticsNode` existed on these screens, and
  this state was 23% of jackdaw_flutter's screen and 18% of genui's.
  It is in the framework, so only fewer render objects reduce it here.

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
