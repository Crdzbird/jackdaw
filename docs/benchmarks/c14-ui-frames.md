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
- Each side draws its screen alone on screen, in alternating order: a
  warm-up round, then five reported rounds. The run is repeated four
  times, so each number below is the median of twenty rounds.
- Then both screens sit one above the other and take 120 data writes
  each, the sides taking turns one frame each, so the writes of both
  meet the core at the same clock; see "Writes on a shared clock". Each
  frame counts for the side that wrote in it.
- Before those writes, about 48 MB that dies at once is allocated, so
  the two screens just mounted are promoted out of the young
  generation instead of being copied in a collection during the writes.
- A spinner keeps frames coming.
- Each round checks that the screen was really drawn, down to its last
  text, field and checkbox, before its numbers count.
- Frame timings arrive in batches, so each frame is assigned to the
  creation or the write phase by the time its build started, not by when
  its timing arrived.
- Before the screen arrives, the UI thread is kept busy for 200 ms, as
  it is at the end of a generation; see "The clock speed" below.

## Results on the reference device

Pixel 7 Pro, Android, 120 Hz, so the frame budget is 8.3 ms.

| Median of 20 rounds, Flutter 3.47.7 | jackdaw_flutter | genui |
|---|---|---|
| Applying the screen's messages | 0.18 ms | 0.40 ms |
| Screen received to first frame | 8.2 ms | 11.4 ms |
| Screen fully drawn | 8.7 ms | 13.0 ms |
| Slowest build while creating | 7.5 ms | 9.3 ms |
| Raster while creating, p99 | 4.4 ms | 4.8 ms |
| Applying one data write | 0.092 ms | 0.120 ms |
| Frame build during writes, p50 | 2.4 ms | 6.3 ms |
| Frame build during writes, p99 | 5.5 ms | 13.5 ms |
| Frame build during writes, max | 7.4 ms | 16.7 ms |
| Raster during writes, p99 | 5.3 ms | 5.8 ms |
| Builds over the budget during writes | 0 | 21.5 |

Over all twenty rounds, jackdaw_flutter went over the 8.3 ms budget 11
times: three times while creating (10.6 to 13.8 ms) and eight times
during writes (8.6 to 13.5 ms). genui went over in 16 of the 20
creations and 499 times during writes. Earlier traces put
jackdaw_flutter's slow write frames down to garbage collection pauses,
so C14 is close but not met; see "Garbage collection".

The table is from 2026-10-16, with one render object per component and
dividers drawn by one; see "Memory per component".

### Writes on a shared clock

Writes used to be measured with each side alone on screen. That made
jackdaw_flutter look slower to apply a write, 0.102 ms against 0.085
ms, because its write frames are lighter and the core clocked down
further between them. Timed in the same frames, a write costs 23 us
against 54 us for genui, and with one write per frame, the sides
alternating, 90 us against 117 us. The writes now alternate frame by
frame on one screen for the same reason. With both screens freshly
mounted together, the first young collection during the writes copied
both, a pause of 17 to 45 ms that landed on whichever side owned the
frame, so the heap is settled first. With each side alone, the medians
were 3.1 ms against 4.7 ms at p50 and 4.7 ms against 10.2 ms at p99:
genui's frames grew most once the clock was shared.

### With the fix in Flutter

These runs predate the shared clock for writes and the single render
object per component.

Every render object built semantics state when it was attached, even
with semantics off; see "Memory per component". The fix is proposed in
[flutter/flutter#194557](https://github.com/flutter/flutter/pull/194557),
for [flutter/flutter#194556](https://github.com/flutter/flutter/issues/194556).
Built on Flutter 3.47.7 with that change, alternated with the runs above:

| Median of 20 rounds | jackdaw_flutter | genui |
|---|---|---|
| Screen received to first frame | 8.1 ms | 10.6 ms |
| Screen fully drawn | 8.7 ms | 11.7 ms |
| Slowest build while creating | 7.4 ms | 8.7 ms |
| Frame build during writes, p99 | 5.0 ms | 10.1 ms |
| Frame build during writes, max | 5.7 ms | 12.6 ms |
| Builds over the budget during writes | 0 | 3 |
| Live heap per component, mixed screen | 25.4 KB | 31.5 KB |

Creation got faster on both sides and the writes did not change, as
the fix only removes work done when a render object is attached.
jackdaw_flutter went over the budget eight times again, seven while
creating and once during writes (9.9 ms); genui went over in 13 of the
20 creations and 103 times during writes.

The build in the whole creation window, which also covers the half
second of spinner frames after the screen, is higher for jackdaw_flutter,
83 ms against 58 ms, but not because it does more. With the core kept
equally busy between frames on both sides, by a 2 ms spin after each
frame, the window came to 119.2 ms against 118.8 ms, idle frames to
0.96 ms against 0.98 ms each, and the five frames after the screen to
1.9 ms against 2.9 ms. A trace of six rounds per side found the
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
| Mixed bench screen | 33.2 KB | 40.4 KB |
| Text | 6.8 KB | 15.4 KB |
| TextField | 74.9 KB | 78.6 KB |
| CheckBox | 50.6 KB | 55.5 KB |
| Slider | 26.3 KB | 35.5 KB |
| Divider | 3.3 KB | 9.8 KB |

- Almost all of it is Flutter's own widgets. A Material text field
  keeps about 76 KB on either side, with 156 closures, 8 animation
  controllers and 59 observer lists, and the eight fields hold 600 of
  the mixed screen's 1,385 KB.
- jackdaw's own objects, the component, its node, its widget and state,
  take about 0.3 KB per component.
- jackdaw_flutter gave each component two render objects, its layer
  and, in a column, a stretch wrapper, and a Divider kept 12.2 KB
  against 9.0 KB for genui. `UiLayer` is now both, one render object,
  and a Divider is `UiRule`, one render object that paints the same
  pixels as Material's eight in Material 2 and 3. The mixed screen
  keeps 1,293 KB instead of 1,385 KB.
- Every render object keeps semantics state even with semantics off:
  `RenderObject.attach` reads its semantics configuration before
  anything checks for a semantics owner, which builds a
  `SemanticsConfiguration`, five `AttributedString`s, four lists and a
  map, about 560 bytes. No `SemanticsNode` existed on these screens, and
  this state was 23% of jackdaw_flutter's screen and 18% of genui's.
  With a semantics owner check before that read, proposed in
  [flutter/flutter#194557](https://github.com/flutter/flutter/pull/194557),
  the mixed screen keeps 991 KB instead of 1,385 KB with
  jackdaw_flutter and 1,229 KB instead of 1,575 KB with genui.

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
  moved all of their building into the layout phase. `UiStretch`, now
  part of `UiLayer`, gives each child the full width when it is
  bounded, during layout. On the
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
