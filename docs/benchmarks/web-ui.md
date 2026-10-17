# Agent-built UI in the browser: jackdaw_dom against genui_jaspr

jackdaw_dom draws jackdaw's A2UI surfaces as plain HTML elements, with no
framework. genui_jaspr, from Very Good Ventures, draws A2UI surfaces with
Jaspr, a component framework for the web built on a2ui_core. This page
compares the two on the screen of the C14 comparison.

## Method

`apps/jackdaw_web_bench`, run with `python3 tool/run_bench.py js 2` and
`python3 tool/run_bench.py wasm 2`. No model is involved: both sides get
the same A2UI messages.

- The screen is a column of 40 components: texts, text fields,
  checkboxes, sliders and dividers, all bound to the data model.
- jackdaw_dom gets the A2UI v1.0 messages through
  `UiDomController.applyAll` and draws them with `UiDomView`.
- genui_jaspr 0.1.0 gets the same messages lowered to A2UI v0.9 by
  `uiLowerToV09`, done before the clock starts. Applying them parses
  them with `A2uiMessage.fromJson` and hands them to a2ui_core's
  `MessageProcessor`; its `Surface` draws them in the page's one Jaspr
  app. Its `createSurface` is applied before the clock starts, since a
  `Surface` needs the surface to exist.
- Both libraries change the DOM in the task that applies the messages or
  in a microtask right after it, so "to drawn DOM" is the time from the
  messages to the last component's text being in the page, read after
  the microtasks. The layout this forces is timed on its own, and so is
  the time to the next animation frame.
- Each side draws its screen in turn, in alternating order: a warm-up
  round, then ten reported rounds. Then both screens take 120 data
  writes each, the sides taking turns one frame each, and each write is
  timed from the message to the DOM showing it.
- Memory is measured in separate rounds with
  `performance.measureUserAgentSpecificMemory`, JavaScript and DOM
  together, before and after a screen, because the collection it runs
  disturbs the frames around it.
- The page is served cross-origin isolated, so its clock reads to 5 us.
  Chrome runs headless at background priority, as heavy jobs on this
  machine do, so absolute times are slower than in a foreground tab;
  both sides run under the same conditions.

Apple M3 Max, macOS 26.6.2, Chrome 155.0.8059.80, Dart 3.13.5. The
pages are compiled with `dart compile js -O2` and `dart compile wasm
-O2`.

## Results

Medians of 20 rounds for times, and of 6 rounds for memory, unless the
table says otherwise.

| Compiled to JavaScript, 60 rounds | jackdaw_dom | genui_jaspr |
|---|---|---|
| Applying the screen's messages | 1.03 ms | 0.44 ms |
| Messages to drawn DOM | 2.9 ms | 11.5 ms |
| Layout the screen forces | 1.3 ms | 1.4 ms |
| Messages to the next frame | 7.9 ms | 17.2 ms |
| Elements of the screen | 80 | 81 |
| Memory the screen adds, JavaScript and DOM | 69 KB | 247 KB |
| Write to the DOM showing it, p50 | 0.22 ms | 0.34 ms |
| Write to the DOM showing it, p99 | 0.69 ms | 1.05 ms |
| Write to the DOM showing it, max | 0.99 ms | 1.45 ms |
| Layout a write forces, p99 | 0.76 ms | 0.74 ms |

| Compiled to WebAssembly, 60 rounds | jackdaw_dom | genui_jaspr |
|---|---|---|
| Applying the screen's messages | 0.43 ms | 0.18 ms |
| Messages to drawn DOM | 1.7 ms | 6.2 ms |
| Layout the screen forces | 1.4 ms | 1.3 ms |
| Messages to the next frame | 6.0 ms | 10.8 ms |
| Elements of the screen | 80 | 81 |
| Memory the screen adds, JavaScript and DOM | 51 KB | 233 KB |
| Write to the DOM showing it, p50 | 0.16 ms | 0.21 ms |
| Write to the DOM showing it, p99 | 0.48 ms | 0.69 ms |
| Write to the DOM showing it, max | 0.92 ms | 1.29 ms |
| Layout a write forces, p99 | 0.82 ms | 0.76 ms |

These runs are from 2026-10-17, with all 18 components in jackdaw_dom
and the lighter checks of "Applying the messages". Each table pools
three runs of 20 rounds, since one run of 20 can move a write's p99 by
0.3 to 0.4 ms: a round's p99 ranges from about 0.3 to 3.8 ms on both
sides, and a few rounds on each side reach 10 to 19 ms.

Pooled, jackdaw_dom draws the screen three to four times sooner, keeps a
fifth to a third of the memory, and shows a write sooner at every
percentile. Applying the messages takes it longer: that time is jackdaw
validating them, and for a write it also includes the DOM update, which
genui_jaspr makes in the microtask after. The layout the browser does
afterwards is about the same for both, since both draw the same
elements.

## Applying the messages

`web/apply_breakdown.dart` times each step of applying the screen's
`createSurface` on fresh surfaces, 300 times in a loop and 60 times
once each after a pause filled with other work, the way the bench meets
it. Before the changes below, compiled to JavaScript:

| One screen | Warm | After a pause |
|---|---|---|
| jackdaw_dom, all of applying | 0.105 ms | 0.29 ms |
| of which the schema check | 0.040 ms | 0.12 ms |
| of which the tree check | 0.040 ms | 0.09 ms |
| of which the components and data model | 0.015 ms | 0.08 ms |
| genui_jaspr, parsing and processing | 0.045 ms | 0.15 ms |

The tree check walked the whole props schema of every component looking
for child references, and compared each schema reference against every
common type by building a string per type. Leaves, 35 of the screen's
40 components, now skip the walk, and a reference's type is looked up
once. The schema check went over each object's keys twice and now does
it once. Warm, applying the screen fell to 0.070 ms compiled to
JavaScript and 0.035 ms compiled to WebAssembly, and in the bench above
from 1.30 to 1.03 ms and from 0.58 to 0.43 ms. The bench's figures are
larger than the breakdown's because each round applies a screen once,
after seconds of writes and frames, with the core at background
priority.

The tree check then stopped copying its list of ancestors for every
child and looks each component up in the catalog once instead of three
times, and the schema check loops where it built a closure for each
choice of schemas and each map. Over 60 more rounds, applying the
screen took 0.83 ms against 0.47 ms for genui_jaspr compiled to
JavaScript, from 1.03 ms against 0.44 ms, and 0.35 ms against 0.20 ms
compiled to WebAssembly, from 0.43 ms against 0.18 ms. That pair of
runs was slower overall, for genui_jaspr too, so only the apply rows
are compared here.

Run without its checks, jackdaw applies the screen in 0.42 ms against
0.39 ms for genui_jaspr, compiled to JavaScript over 20 rounds; without
the schema check alone 0.84 ms, and without the tree check alone
0.76 ms, against 1.09 ms with both. What is left is jackdaw checking what it is sent: the message against
the catalog's schemas and the tree for missing children, cycles and
placements, which genui_jaspr's path does not do. Checking a write
against only the variant its envelope names was tried and left out:
the variants tried first fail on their first required key, so it saved
nothing measurable.

## Trusted messages

The checks stay on by default. An app can pass `trusted: true` to
`UiDomController.applyAll`, or to `UiSurfaces.applyAll` and jackdaw_flutter's
`UiSurfaceController.applyAll`, for messages from a source it fully
trusts, such as its own server; those skip the schema check and the
tree check. Never for a model's answer or another agent's: a malformed
message is then not caught, and may throw or draw wrongly. The renderers
still draw nothing for an unknown component, a missing child or a cycle.

The bench runs a third side, jackdaw_dom with `trusted: true`, in the
same rounds. Medians of 60 rounds:

| | jackdaw_dom | jackdaw_dom, trusted | genui_jaspr |
|---|---|---|---|
| Applying the screen, JavaScript | 0.68 ms | 0.26 ms | 0.45 ms |
| Messages to drawn DOM, JavaScript | 2.4 ms | 1.9 ms | 11.0 ms |
| Write to the DOM showing it, p50, JavaScript | 0.21 ms | 0.19 ms | 0.32 ms |
| Applying the screen, WebAssembly | 0.41 ms | 0.14 ms | 0.19 ms |
| Messages to drawn DOM, WebAssembly | 1.7 ms | 1.3 ms | 5.5 ms |
| Write to the DOM showing it, p50, WebAssembly | 0.15 ms | 0.14 ms | 0.21 ms |

Trusted, jackdaw_dom applies the screen faster than genui_jaspr; checked,
the price of the checks is about 0.4 ms compiled to JavaScript and
0.3 ms compiled to WebAssembly for this screen, and it still reaches the
drawn DOM four times sooner.

## Script size

What each library adds to a page, measured with the smallest page that
draws the bench screen with only that library, compiled the same way:

| Page script | jackdaw_dom | genui_jaspr |
|---|---|---|
| JavaScript | 219 KB, 69 KB gzipped | 508 KB, 141 KB gzipped |
| WebAssembly | 172 KB, 68 KB gzipped | 476 KB, 161 KB gzipped |

Both draw all 18 components of the basic catalog, icons included.
jackdaw_dom's page carries jackdaw's schemas, validation, data model and
expression evaluator, and genui_jaspr's carries Jaspr and a2ui_core.

## Why they differ

- jackdaw_dom builds each element once. A write goes through the index
  of paths to the components that read it and sets one `textContent` or
  `value` in place. genui_jaspr rebuilds the Jaspr components that
  depend on the written signal and reconciles them with the DOM.
- jackdaw_dom validates every message against the catalog's schemas
  before it applies, which is most of its time to apply the screen; it
  still reaches the drawn DOM first. On genui_jaspr's path, a2ui_core
  parses the messages into typed objects and applies them; it uses the
  catalog's schemas to describe the catalog, not to check messages.
- Both draw the same elements: labels, inputs, paragraphs and rules,
  80 against 81 for the screen. jackdaw_dom creates a field's error and
  a slider's caption only when there is text for them.
