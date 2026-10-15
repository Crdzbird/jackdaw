# ADR 0002: generative UI

Status: Accepted (2026-10-15); steps 1 to 4 built

## Context

jackdaw must also do generative UI: the model answers with interface, not
only with text and tool calls. ADR 0001 did not cover it; the competitor
survey lists Flutter's `genui` package only as a UI layer that exists.

What exists today, checked on 2026-10-15:

- A2UI (a2ui-project) is the wire format. v0.9.1 is the production
  version; v1.0 is a release candidate with a high bar for breaking
  changes. Both define agent-to-renderer messages (`createSurface`,
  `updateComponents`, `updateDataModel`, `deleteSurface`) and
  renderer-to-agent `action` and `error` messages by JSON Schema.
  Components are a flat list with ids, one of them `root`, and children
  are referenced by id; values may bind to data model paths.
- The A2UI basic catalog has 18 components (Text, Image, Icon, Video,
  AudioPlayer, Row, Column, List, Card, Tabs, Modal, Divider, Button,
  TextField, CheckBox, ChoicePicker, Slider, DateTimeInput) and 14
  functions (required, regex, length, numeric, email, formatString,
  formatNumber, formatCurrency, formatDate, pluralize, openUrl, and, or,
  not).
- `genui` 0.10.6 (flutter labs, BSD-3) renders A2UI v0.9 on its own
  inlined copy of `a2ui_core` 0.1.0. It announces a redesign into
  `a2ui_core`, `a2ui_agent` and `a2ui_flutter`. `a2ui_core` 0.3.0
  (Apache-2.0) parses and validates v0.9, v0.9.1 and v1.0; `a2ui_flutter`
  renders v0.9 and is not published yet.

### v0.9.1 or v1.0

v1.0 has the better tools for this design:

- `createSurface` carries the components and the initial data model, so
  a whole screen is one message. One message is one constrained tool
  call, which is what a small local model does reliably.
- Bindings and function calls use reserved keys (`@path`, `@call`,
  `@index`), so data such as `{"path": "/tmp"}` is no longer mistaken for
  a binding. A grammar can tell the two apart.
- Catalogs declare composition rules (`allowedParents`,
  `allowedChildren`), usage `instructions` for the prompt, deprecations,
  and which side may call each function.
- Checks return structured `ValidationResult`s, accessibility attributes
  gain live regions and `hidden`, and both sides can call functions on
  the other (`callRendererFunction`, `callAgentFunction`).

The cost is that genui 0.10.x accepts only v0.9. That is handled in the
adapter, not by holding the core back.

## Decision

jackdaw targets A2UI v1.0. The model emits A2UI v1.0 agent-to-renderer
messages, the Flutter renderer applies them, and the renderer answers
with A2UI v1.0 renderer-to-agent messages. No second, jackdaw-specific
UI format exists.

### Two ways to emit UI

- During a turn, as a tool call: `uiTool(catalog)` is a `Tool` named
  `render_ui` whose input is a list of A2UI messages. Approval,
  journaling, tracing, redaction and screening apply to it as to any
  tool, and a session journal replays the UI after a restart.
- As the whole answer: `uiResponse(catalog)` is a response schema, so a
  screen that is only UI is one structured-output call, constrained the
  same way as C1.

All four agent-to-renderer messages are supported in both, plus
`callRendererFunction` for the catalog's renderer functions.

### Catalogs

- `UiCatalog` lists `UiComponent`s and `UiFunction`s, each with a name, a
  props or arguments schema, composition rules and the side allowed to
  call it. It is read from and written as an A2UI v1.0
  `catalog_definition` document, so catalogs are portable.
- jackdaw ships the whole A2UI v1.0 basic catalog: all 18 components and
  all 14 functions. Apps add their own components and may mix catalogs,
  as v1.0 allows.
- The catalog's `instructions` and the component list go into the system
  prompt, sized to the context budget.

### Constrained output

- The schema for `render_ui` and `uiResponse` is generated from the
  catalog: each component is a tagged alternative with its own props
  schema, and each prop is either a literal, an `@path` binding or an
  `@call` to a catalog function.
- jackdaw's schemas have no union type today, and `anyOf` is kept only
  as an uncompiled `RawSchema`. A `UnionSchema` with a discriminator
  property is added to the schema library and compiled to a grammar
  alternative, so local models can only emit components that exist with
  props that validate. Cloud models get the same schema.
- Composition rules and id references cannot be expressed in a grammar
  over a flat list. They are checked on the device after decoding, and a
  violation goes back to the model as an A2UI `error` message.

### Rendering in Flutter

`jackdaw_flutter` gains `UiSurfaceController` (surfaces, data model,
function evaluation, validation) and `UiSurfaceView`, which builds each
component through a builder registered for its catalog name; the basic
catalog's 18 builders are included. `ChatView` shows surfaces inline in
the transcript. The one-update-per-frame and keyed-layout rules of
streaming text apply, so a surface that updates does not rebuild the
whole list. Every component plumbs its accessibility attributes into
Flutter semantics, as v1.0 requires.

### Model output is untrusted

Generated UI is data, never code:

- Components and functions outside the catalog are not rendered or run;
  every message is validated again on the device, whatever the model was
  constrained to.
- Limits on components per surface, nesting depth, data model size and
  text length.
- A user action never runs a tool by itself: it becomes an `action`
  message the agent sees on its next turn. A `callAgentFunction` from
  the renderer is a tool call and goes through the tool policy and
  approval.
- `openUrl`, images, video and audio load only from hosts the app allows,
  and `openUrl` needs a user gesture, as the catalog declares.
- Text read back into the model goes through the same injection
  screening as tool output.

### Adapter: `jackdaw_genui`

A separate package, so the core does not depend on a 0.x labs package:

- Implements genui's `onSend` with any jackdaw `Agent`, so genui apps get
  local models, offline use, sessions and tool policies.
- genui 0.10.x speaks v0.9 only, so the adapter lowers v1.0 to v0.9.1: a
  `createSurface` with components becomes `createSurface` plus
  `updateComponents` and `updateDataModel`, `@path` and `@call` lose their
  prefix, and catalogs drop v1.0-only fields. v1.0-only features
  (function calls between sides, composition rules) are not available
  through genui 0.10.x.
- When the redesigned `a2ui_flutter` ships with v1.0 support, the adapter
  passes messages through unchanged.
- It is tested against recorded genui fixtures and pins the genui and
  A2UI versions it supports. New dependencies are added only with
  approval.

## Consequences

- One mechanism for tools and UI keeps the agent loop simple and gives
  UI the same guarantees as tools, on cloud, device and web models.
- Constraining UI with a grammar is the differentiator: small local
  models produce valid UI, which prompt-only approaches do not promise.
- Using A2UI v1.0 directly means any v1.0 renderer can show jackdaw's
  output, and jackdaw can render any v1.0 agent's output.
- A release candidate can still change; jackdaw pins the spec commit it
  implements and tracks the stable release.

## Claims

- C13: at least 99% of UI messages from a local model validate against
  the basic catalog, including composition rules, on a suite of 200 UI
  prompts, as C1 does for JSON.
- C14: applying a UI message and rendering the surface loses no frame on
  the reference device.

## Build order

1. `UnionSchema` and its grammar compilation, with the property and
   fuzz tests the grammar compiler already has.
2. A2UI v1.0 message and catalog types in `jackdaw`, the basic catalog
   definition, validation and the 14 functions, in pure Dart so they run
   on the web.
3. `uiTool` and `uiResponse`, and `action` messages in the agent loop.
4. `UiSurfaceController`, `UiSurfaceView` and the 18 builders in
   `jackdaw_flutter`, with golden and semantics tests.
5. The C13 suite on the Mac and the Pixel, and C14 on the Pixel.
6. `jackdaw_genui`.

## Implementation notes (2026-10-15)

Steps 1 to 4 are built, step 5 is measuring, and step 6 is built as
targets; the user approved a2ui_core as a dependency and asked for genui
to be a choice rather than a requirement.

Schemas. Besides `UnionSchema`, the schema library gained `AnyOfSchema`,
`MapSchema`, `SummarizedSchema` and array `minItems`, `maxItems` and
`prefixItems`. Optional properties became optional in grammars (the C1
and C2 bench schemas mark every property required, so their grammars
did not change), a schema used in several places compiles to one rule,
and `sharedSchemaJson` writes repeated parts once under `$defs`: the UI
schema is 38 KB that way instead of 9.8 MB. Local prompts show a 4 KB
catalog guide with one worked example instead of the schema.

What a model may send is stricter than what the protocol accepts. The
reply schema lets only the first message create a surface, makes that
surface's first component the root, and allows at most 4 messages, 40
components per message and 40 ids per list of children. Messages from
other agents are validated against the A2UI rules as they are.

Running the tool with Qwen2.5 1.5B, Llama 3.2 3B and Gemma 2 2B changed
the design in five places:

- A component the root does not reach is a warning, not an error: A2UI
  just does not show it, and treating it as an error made models resend
  the same screen in a loop.
- With `adoptOrphans`, on by default, components nothing refers to join
  the root's children in the order they were sent, because small models
  often define a component and forget to list it.
- Creating a surface that exists replaces it, since models resend whole
  screens to correct them.
- A call with errors changes nothing and fails through the new
  `ToolFailure`, so the model gets structured problems to fix.
- `Tool.maxCallsPerTurn` stops offering a tool after that many successful
  calls since the user's last message; `render_ui` allows one. Llama
  called it until the step limit before, and once after.

Requiring at least one child in a list was tried and dropped: Gemma then
wrote fragments of JSON as child ids.

Most remaining failures were structural: on 20 requests Qwen referred 13
times to ids it never defined, repeated ids 4 times and made 3 components
contain themselves. So models now write a screen as a tree by default
(`UiFormat.tree`): a `surfaceId`, a `root` component and a `dataModel`,
where containers hold their children inside them, six levels deep at
most. With no ids there is nothing to dangle, repeat or loop.
`uiTreeMessages` turns the tree into one A2UI v1.0 `createSurface`, so
everything downstream still receives standard A2UI; the flat format
stays available as `UiFormat.messages`.

Targets. `uiTool`, `generateUi` and `uiReplay` take a `UiTarget`: where
the A2UI messages go. `UiTarget.surfaces` is jackdaw's own, drawn by
jackdaw_flutter; `UiTarget.forward` checks messages against a shadow copy
and hands the ones that show to any renderer that reads A2UI v1.0, such
as one built on a2ui_core; `UiTarget.genui` does the same lowered to
A2UI v0.9 for genui 0.10, without jackdaw depending on genui. Any other
library plugs in by implementing `UiTarget`. The jackdaw_a2ui package
adds `A2uiCoreTarget` on a2ui_core's message processor; the published
a2ui_core 0.2 reads A2UI v0.9 only (v1.0 is in its unreleased 0.3), so
this target lowers messages too, and what a2ui_core rejects comes back
to the model as problems.

Rendering. All 18 components have Flutter builders. Video and AudioPlayer
are tiles that open the media through `UiHost`, because jackdaw_flutter
depends on Flutter alone; an app that wants playback registers its own
builders. Icons can also be drawn from SVG path data. Number, currency,
date and plural formatting are English for now.

Restoring a session replays the successful `render_ui` calls of its
transcript (`uiReplay`), so surfaces come back; what the user typed is
not in the transcript and comes back as the agent last sent it.

Not done yet: golden tests (semantics and widget tests cover the
builders), surface metadata and extensions, functions the agent calls on
the renderer and the renderer on the agent (the basic catalog has none),
mixing several catalogs on one surface, and the web model's grammar run
of the UI suite.
