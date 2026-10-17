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
| Applying the screen's messages | 1.30 ms | 0.41 ms |
| Messages to drawn DOM | 3.0 ms | 11.0 ms |
| Layout the screen forces | 1.3 ms | 1.4 ms |
| Messages to the next frame | 8.7 ms | 16.3 ms |
| Elements of the screen | 80 | 81 |
| Memory the screen adds, JavaScript and DOM | 69 KB | 234 KB |
| Write to the DOM showing it, p50 | 0.24 ms | 0.34 ms |
| Write to the DOM showing it, p99 | 0.84 ms | 1.14 ms |
| Write to the DOM showing it, max | 1.41 ms | 1.56 ms |
| Layout a write forces, p99 | 0.73 ms | 0.78 ms |

| Compiled to WebAssembly | jackdaw_dom | genui_jaspr |
|---|---|---|
| Applying the screen's messages | 0.60 ms | 0.22 ms |
| Messages to drawn DOM | 1.9 ms | 7.5 ms |
| Layout the screen forces | 1.4 ms | 1.4 ms |
| Messages to the next frame | 6.5 ms | 13.0 ms |
| Elements of the screen | 80 | 81 |
| Memory the screen adds, JavaScript and DOM | 51 KB | 233 KB |
| Write to the DOM showing it, p50 | 0.17 ms | 0.23 ms |
| Write to the DOM showing it, p99 | 0.58 ms | 0.80 ms |
| Write to the DOM showing it, max | 0.80 ms | 1.62 ms |
| Layout a write forces, p99 | 0.87 ms | 1.02 ms |

These runs are from 2026-10-16 and 17, with all 18 components in
jackdaw_dom. The JavaScript figures pool three runs of 20 rounds, since
one of them put jackdaw_dom's write p99 at 1.14 ms and the other two at
0.74 and 0.82 ms; a round's p99 ranges from 0.4 to 3.8 ms on both sides,
with one jackdaw_dom round at 12.4 ms. jackdaw_dom draws the screen three
to four times sooner, keeps a quarter to a third of the memory, and
shows a write sooner at every percentile. Applying the
messages takes it longer: that time is jackdaw validating them, and for
a write it also includes the DOM update, which genui_jaspr makes in the
microtask after. The layout the browser does afterwards is the same for
both, since both draw the same elements.

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
