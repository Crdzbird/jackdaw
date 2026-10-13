# Gap analysis: Dart and Flutter LLM agent frameworks

Status: accepted 2026-10-12. Gathered 2026-10-12. Name: `jackdaw` (chosen, see
section 9).

This document records what the current Dart/Flutter AI frameworks do, where
they are weak, and which gaps this project should own. It feeds
[ADR 0001](adr/0001-scope-and-architecture.md). Raw research notes with every
source URL are in [docs/research/](research/).

## 1. Method

- Reference implementation: local clone of Genkit Dart at
  `/Users/crdzbird/flutterApps/genkit-dart`. Remote `origin` is the fork
  `Crdzbird/genkit-dart`; `upstream` (`genkit-ai/genkit-dart`) was added during
  this session. Local `main` is level with `upstream/main` (0 ahead, 0 behind),
  HEAD `0d4e6cd` from 2026-10-09.
- Code study: read-only pass over the clone, every claim tied to a file and line
  in [research/genkit-code-study.md](research/genkit-code-study.md).
- Upstream mining: `gh` over all open and closed issues, all 445 PRs, labels and
  releases of `genkit-ai/genkit-dart`, plus Dart-related issues in
  `genkit-ai/genkit`. See [research/genkit-upstream-gaps.md](research/genkit-upstream-gaps.md).
- Competitor survey: pub.dev API (versions, points, likes, 30-day downloads)
  and GitHub issue trackers of the main alternatives. See
  [research/competitor-survey.md](research/competitor-survey.md).
- Platform facts: Dart build hooks, pub.dev limits, Android and iOS packaging,
  runtimes and web options, all with primary sources. See
  [research/native-facts.md](research/native-facts.md).

Signal caveat: community engagement on every tracker is low. Only 5 of 104 open
Genkit Dart issues have any reaction and the maximum is 1. Most issues are
maintainer work trackers. Evidence below therefore leans on maintainer trackers,
spike reports, closed-unmerged PRs and recurring bug classes, not on vote counts.

## 2. Reference implementation facts

| Item | Value |
|---|---|
| License | Apache-2.0, per package (no root LICENSE file) |
| Layout | Melos plus pub workspace, 17 packages, 18 sample apps |
| Core size | `genkit`: about 20k handwritten lib lines, 874 tests; about 2,100 tests repo-wide |
| Stable at 1.0.0 (2026-10-07) | genkit, schemantic, google_genai, vertexai, openai, anthropic, mcp, middleware, shelf |
| Still 0.x | firebase_ai, chrome, otel, a2ui, google_cloud, vertex_auth |
| Experimental at 1.0 | agents, sessions, bidi (live) API |
| Native code | none; no package imports `dart:ffi` |
| Web | `client.dart` is truly web-safe (13 transitive files, no `dart:io`) |
| Release cadence | one minor every 3 to 6 weeks in 2026; Dart waits for JS and Go designs |

What Genkit Dart does well and we must at least match: a browser-safe client,
typed tools and output, middleware with three hook points, tool interrupts with
resume, session snapshots, sub-agent delegation, MCP, OpenTelemetry, a public API
snapshot enforced in CI, and strong CI hygiene (fatal infos, generated code
checks, dartdoc).

## 3. Gap matrix

Priority: P0 = v1 must ship, P1 = v1 if the spike goes well, else v1.x,
P2 = later, Won't = out of scope.

| # | Pain point | Evidence | Who is affected | Can we solve it? | Needs native? | Priority |
|---|---|---|---|---|---|---|
| 1 | Structured output fails on small and local models | [genkit-dart#426](https://github.com/genkit-ai/genkit-dart/issues/426) (Qwen2.5-1.5B on device: 0 of 5 parse), fix is opt-in [#519](https://github.com/genkit-ai/genkit-dart/pull/519); [flutter_edge_ai#195](https://github.com/DenisovAV/flutter_edge_ai/issues/195), [llamadart#174](https://github.com/leehack/llamadart/issues/174), grammar crash [llama_cpp_dart#112](https://github.com/netdur/llama_cpp_dart/issues/112) | On-device and Ollama users | Yes: grammar-constrained decoding by default, schema compiled once | Sampler yes (llama.cpp); schema to grammar compiler no (Dart, shared with web) | P0 |
| 2 | Local tool calling is per-model-family parsing glue that keeps breaking | [flutter_edge_ai#228](https://github.com/DenisovAV/flutter_edge_ai/issues/228), [#367](https://github.com/DenisovAV/flutter_edge_ai/issues/367), [llamadart#741](https://github.com/leehack/llamadart/issues/741), [#1007](https://github.com/leehack/llamadart/issues/1007) | On-device agent builders | Yes: force tool calls through a grammar we own instead of parsing each family's free text | Same as row 1 | P0 |
| 3 | On-device inference is not first-party in any agent framework | [genkit-dart#384](https://github.com/genkit-ai/genkit-dart/issues/384) (spike: "point at the community plugin"), [#383](https://github.com/genkit-ai/genkit-dart/issues/383), [dartantic#22](https://github.com/csells/dartantic/issues/22), [langchain_dart#931](https://github.com/davidmigloz/langchain_dart/issues/931) | Flutter devs wanting offline, private, zero-cost agents | Yes | Yes (llama.cpp) | P0 |
| 4 | Native lifecycle bugs: cancel does not stop decode, UI isolate blocked, memory not released, model reloaded per call, slowdown every turn | [llama_cpp_dart#105](https://github.com/netdur/llama_cpp_dart/issues/105), [#88](https://github.com/netdur/llama_cpp_dart/issues/88), [#79](https://github.com/netdur/llama_cpp_dart/issues/79), [flutter_edge_ai#373](https://github.com/DenisovAV/flutter_edge_ai/issues/373), [#364](https://github.com/DenisovAV/flutter_edge_ai/issues/364), [#402](https://github.com/DenisovAV/flutter_edge_ai/issues/402) (about 65 MB leak per inference), [#348](https://github.com/DenisovAV/flutter_edge_ai/issues/348), [fllama#15](https://github.com/Telosnex/fllama/issues/15), [llamadart#634](https://github.com/leehack/llamadart/issues/634) | Every on-device user | Yes: native worker thread, cooperative cancel flag checked per token, KV prefix reuse, owned memory accounting | Yes | P0 |
| 5 | Native packaging is the number one complaint class: toolchains, 16 KB pages, dlsym, App Store rejection, ggml symbol collisions | [llama_cpp_dart#50](https://github.com/netdur/llama_cpp_dart/issues/50), [#104](https://github.com/netdur/llama_cpp_dart/issues/104), [#107](https://github.com/netdur/llama_cpp_dart/issues/107), [flutter_edge_ai#286](https://github.com/DenisovAV/flutter_edge_ai/issues/286), [#457](https://github.com/DenisovAV/flutter_edge_ai/issues/457), [fllama#25](https://github.com/Telosnex/fllama/issues/25), [llama_cpp_dart#61](https://github.com/netdur/llama_cpp_dart/issues/61) | Every on-device user | Yes: prebuilt per-target binaries via build hook, SHA-256 pinned, 16 KB aligned, ggml symbols hidden, CI gates for each | Yes (it is the native story) | P0 |
| 6 | No local RAG: Genkit has no retriever, indexer or reranker; docs are dropped in the generate loop | [genkit-dart tree](https://github.com/genkit-ai/genkit-dart/tree/main/packages/genkit/lib/src/ai), [#243](https://github.com/genkit-ai/genkit-dart/issues/243); [langchain_dart#516](https://github.com/davidmigloz/langchain_dart/issues/516) (sqlite-vec store open since 2024); ObjectBox and sqlite3_vec have no web build | RAG and agent-memory apps, offline knowledge bases | Yes: embeddings plus persistent ANN index plus retriever API | Index yes (USearch); retriever API no | P0 |
| 7 | No token counting or context budgeting anywhere; usage numbers inconsistent | [genkit-dart#611](https://github.com/genkit-ai/genkit-dart/issues/611), [#581](https://github.com/genkit-ai/genkit-dart/issues/581), [flutter_edge_ai#570](https://github.com/DenisovAV/flutter_edge_ai/issues/570), [#571](https://github.com/DenisovAV/flutter_edge_ai/issues/571), tokenizer bugs [llama_cpp_dart#86](https://github.com/netdur/llama_cpp_dart/issues/86), [llamadart#554](https://github.com/leehack/llamadart/issues/554); Dart tiktoken ports stale since 2023 to 2025 | Long conversations, cost control | Partly: exact for local models, provider count endpoints for cloud, estimator with margin otherwise | Local exact counts yes (llama.cpp tokenizer); budget engine no | P0 |
| 8 | Web parity: native-first designs break or degrade on web | [dartantic#36](https://github.com/csells/dartantic/issues/36), [langchain_dart#207](https://github.com/davidmigloz/langchain_dart/issues/207), [#567](https://github.com/davidmigloz/langchain_dart/issues/567), [flutter_edge_ai#244](https://github.com/DenisovAV/flutter_edge_ai/issues/244), [llama_cpp_dart#87](https://github.com/netdur/llama_cpp_dart/issues/87); Genkit web local inference is Chrome Prompt API only (`genkit_chrome` 0.2.0, 0 tests) | Flutter web devs | Yes: same public API, web backend through `dart:js_interop` over wllama, pure-Dart fallbacks | No (web cannot use FFI) | P0 |
| 9 | Typed tool arguments are never validated; validation needs the network | Code study: `validate()` never called from lib code; [genkit-dart#339](https://github.com/genkit-ai/genkit-dart/issues/339), fix [#349](https://github.com/genkit-ai/genkit-dart/pull/349) unreviewed since 2026-08 | Every tool user, offline apps | Yes: offline pure-Dart JSON Schema validator on every tool call and structured result | No | P0 |
| 10 | Tool loop fragility: sequential tools, a throwing tool fails the whole generation, no per-tool timeout | Code study (see research note section 2) | Agent builders | Yes: parallel tool execution with limits, errors returned to the model, timeouts | No | P0 |
| 11 | Tool approval can be granted by the client; no injection defenses; dev reflection server unauthenticated | Code study: approval middleware honours a client `tool-approved: true` flag; reflection server binds loopback with no token or Origin check; [genkit-dart#561](https://github.com/genkit-ai/genkit-dart/issues/561) (symlink sandbox escape), [#478](https://github.com/genkit-ai/genkit-dart/pull/478); [dartantic#12](https://github.com/csells/dartantic/issues/12) | Anyone shipping agents with side-effecting tools | Yes: server-authoritative policy engine, taint marking of tool and retrieval output, redaction by default | No (Dart is enough) | P0 |
| 12 | Native Ollama declined; OpenAI-compatible path cannot set `numCtx` or `topK` and blocks on unreachable hosts | Closed series [#305](https://github.com/genkit-ai/genkit-dart/pull/305) to [#309](https://github.com/genkit-ai/genkit-dart/pull/309), [#113](https://github.com/genkit-ai/genkit-dart/issues/113) (stale 240 days), [#229](https://github.com/genkit-ai/genkit-dart/issues/229), [#421](https://github.com/genkit-ai/genkit-dart/issues/421) | Local-first desktop users | Yes: native Ollama provider plus a fast-failing OpenAI-compatible provider | No | P0 |
| 13 | Per-request cancellation missing; Retry-After ignored | [genkit-dart#460](https://github.com/genkit-ai/genkit-dart/issues/460), [#456](https://github.com/genkit-ai/genkit-dart/issues/456), [#588](https://github.com/genkit-ai/genkit-dart/issues/588) | Flutter UIs with stop buttons, production users | Yes: own the HTTP and SSE layer | No | P0 |
| 14 | Agents and sessions experimental at 1.0 with basic state bugs | [#450](https://github.com/genkit-ai/genkit-dart/pull/450), [#626](https://github.com/genkit-ai/genkit-dart/issues/626), [#628](https://github.com/genkit-ai/genkit-dart/issues/628), [#629](https://github.com/genkit-ai/genkit-dart/issues/629) | Multi-turn agent builders | Yes: small stable agent API, durable event log, typed state | No | P0 |
| 15 | Codegen pain: build_runner plus analyzer, conflicts with riverpod, no interop with Freezed or json_serializable | [#222](https://github.com/genkit-ai/genkit-dart/issues/222) (most-commented issue; maintainer calls analyzer "the biggest liability"), [#227](https://github.com/genkit-ai/genkit-dart/pull/227) draft since March, [#270](https://github.com/genkit-ai/genkit-dart/issues/270), [#228](https://github.com/genkit-ai/genkit-dart/issues/228) | Every typed-tool user | Yes: codegen-free schema builder that works with any existing `fromJson` | No | P0 |
| 16 | Prompt caching, Responses API, Azure, Bedrock, Mistral, Hugging Face stalled | [#109](https://github.com/genkit-ai/genkit-dart/issues/109), [#372](https://github.com/genkit-ai/genkit-dart/issues/372) ("blocked on JS design"), [#115](https://github.com/genkit-ai/genkit-dart/issues/115), [#345](https://github.com/genkit-ai/genkit-dart/issues/345), [#116](https://github.com/genkit-ai/genkit-dart/issues/116) | Cost-sensitive and enterprise users | Yes, incrementally | No | P1 (caching, Responses), P2 (others) |
| 17 | Dev UI is hard with Flutter (Node CLI, adb reverse, four dart-defines) | [#204](https://github.com/genkit-ai/genkit-dart/issues/204), [#254](https://github.com/genkit-ai/genkit-dart/issues/254), [#428](https://github.com/genkit-ai/genkit-dart/issues/428), [genkit#5502](https://github.com/genkit-ai/genkit/issues/5502) | Flutter developers | Yes: Dart-native trace inspector | No | P2 |
| 18 | No built-in evaluators; no published test kit (fake models are inline in tests) | [#247](https://github.com/genkit-ai/genkit-dart/issues/247), [#248](https://github.com/genkit-ai/genkit-dart/issues/248), [dartantic#19](https://github.com/csells/dartantic/issues/19) | Teams doing eval-driven development | Yes: `jackdaw_test` with mock provider and fixture recorder in v1, evaluators later | No | P0 (test kit), P2 (evaluators) |
| 19 | Realtime voice (bidi) experimental and incomplete | [#461](https://github.com/genkit-ai/genkit-dart/pull/461), [#597](https://github.com/genkit-ai/genkit-dart/issues/597), [#590](https://github.com/genkit-ai/genkit-dart/issues/590) | Voice assistants | Yes, but large | No | P2 |
| 20 | Custom HTTP client or proxy cannot be injected | [#221](https://github.com/genkit-ai/genkit-dart/issues/221) (stale 202 days) | Corporate networks, debugging | Yes: every provider takes an injected client | No | P0 |
| 21 | Community PRs wait months; one maintainer authors 239 of 358 merged PRs | [#335](https://github.com/genkit-ai/genkit-dart/pull/335), [#349](https://github.com/genkit-ai/genkit-dart/pull/349), [#186](https://github.com/genkit-ai/genkit-dart/pull/186) | Contributors | Partly: our own governance; not a product feature | No | n/a |
| 22 | MCP OAuth client not wanted by Genkit maintainers | [#186](https://github.com/genkit-ai/genkit-dart/pull/186) | Agents using remote authenticated MCP servers | Yes, via existing `dart_mcp` or `mcp_dart` | No | P2 |

## 4. Competitor landscape

Full tables with versions, pub points, likes and downloads are in
[research/competitor-survey.md](research/competitor-survey.md).

| Competitor | Strength | Weakness relevant to us |
|---|---|---|
| Genkit Dart 1.0 (Apache-2.0, 33k downloads in 30 days) | Google backing, flows, dotprompt, tracing, MCP, browser-safe client | Rows 1 to 22 above; on-device and RAG absent |
| dartantic_ai 3.4 (BSD-3) | Simple `Agent` API, 10+ providers, MCP | No local inference in core, no release since 2026-07, structured output plus tools fragile ([#32](https://github.com/csells/dartantic/issues/32), [#71](https://github.com/csells/dartantic/issues/71)) |
| langchain_dart 0.9 (MIT) | Breadth, LCEL, mature provider SDKs (`ai_clients_dart`) | Only in-memory or ObjectBox vectors, recurring web and streaming tool-call bugs |
| llamadart 0.11 (MIT, 59 releases since 2026-01) | Strongest direct threat: llama.cpp plus LiteRT-LM, hook-delivered prebuilt binaries, experimental WebGPU web, grammars, tool loop, adapters for Genkit and Dartantic | Engine library, not an agent framework; web experimental; open issues on structured output validation, memory growth, isolate supervision |
| flutter_edge_ai 2.2 (ex flutter_gemma, MIT, most downloaded on-device package) | Widest engine coverage (LiteRT-LM, MediaPipe, ONNX, OS models), NPU, RAG via sqlite-vec or Qdrant Edge | No constrained decoding, lifecycle and memory bugs (row 4), packaging complaints |
| nobodywho 5.1 (EUPL-1.2, Rust core) | Multi-runtime reach, 1.5k stars | Weak copyleft, no web |
| ObjectBox 5.3 | Mature persistent HNSW | No web |

What we will not try to beat in v1: raw cloud provider breadth (dartantic and
`ai_clients_dart`), engine breadth and Google model formats (flutter_edge_ai),
official MCP and UI packages (`dart_mcp`, `flutter_ai_toolkit`, `genui`).

Strategic consequence: "on-device inference" alone is not a differentiator any
more, because llamadart and flutter_edge_ai ship it. The opening is the
combination nobody has: an agent framework where local and cloud models share
one runtime with constrained output, exact budgets, local RAG, a security
policy layer and identical behaviour on web, all measured.

## 5. Differentiators as measurable claims

All numbers are targets to be validated in the Phase 2 spike, not results.
"Reference device" is a Google Pixel 7 Pro (Tensor G2, 12 GB RAM, 2022), a
four-year-old former flagship used as the mid-tier proxy. "Reference model" is a 1.5B to 3B instruct model in
GGUF Q4 (Qwen2.5-1.5B-Instruct is the default candidate because it is the model
Genkit's own report used).

| ID | Claim | How it is measured | Gap rows |
|---|---|---|---|
| C1 | At least 99% schema-valid structured output from the reference model, native and web | Checked-in suite of 200 schemas and prompts; validator decides; compared with unconstrained decoding and with Genkit plus `genkit_llamadart` | 1 |
| C2 | At least 98% well-formed tool calls across three model families (Qwen, Llama, Gemma) with no per-family parser | Same suite, tool variant | 2 |
| C3 | Cancel stops native decoding within 100 ms at p95 | Timestamp from `cancel()` to last token callback, 100 runs, reference device | 4 |
| C4 | No memory growth: RSS after 100 load and dispose cycles within 5% of baseline | Native RSS sampling in an integration test | 4 |
| C5 | Time to first token on turn 20 within 1.5x of turn 2 and at least 10x faster than reprocessing the full prompt (restated 2026-10-13 from 1.2x, see ADR 0001) | KV prefix reuse benchmark, 20-turn chat | 4 |
| C6 | Zero UI-thread frames attributable to inference | Flutter frame timing p99 during generation vs idle, measured in Phase 5 with the widgets | 4 |
| C7 | 100k vectors of 384 dims: recall@10 at least 0.95, p95 query under 10 ms, cold open under 200 ms | Benchmark against exact search, reference device | 6 |
| C8 | Same public API and the same contract test suite pass on Chrome (JS and Wasm builds) | CI job running the shared suite in a browser | 8 |
| C9 | Full agent loop (tools, RAG, schema validation) runs with networking disabled | CI test in a network-less sandbox | 3, 6, 9 |
| C10 | A tool denied by policy cannot be approved by any client message; canary secrets never appear in traces or logs | Adversarial test suite | 11 |
| C11 | Agent state survives process kill at any step and resumes with no duplicated tool side effects | Kill-at-random-step harness with idempotency checks | 14 |
| C12 | Add dependency then `flutter run` works on Android, iOS, macOS, Windows, Linux with no C++ toolchain; Android libraries 16 KB aligned; no exported ggml symbols | CI matrix plus `readelf` and `nm` gates | 5 |

## 6. Parity checklist

| Capability | Decision | Notes |
|---|---|---|
| Unified model interface and provider plugins | v1 | Gemini, OpenAI, Anthropic, Ollama, OpenAI-compatible, local |
| Streaming | v1 | Own SSE and NDJSON parser, per-request cancel, Retry-After |
| Tool calling with typed inputs | v1 | Codegen-free schema builder, optional codegen later |
| Structured output | v1 | Native constrained decoding locally; validate and repair for cloud |
| Multi-step agent loop with limits | v1 | Max steps, max tool calls, token and time budgets |
| Sub-agent delegation | v1.x | Agent as a tool; after the loop is stable |
| Sessions and persistent memory | v1 | Durable event log; file store native, in-memory on web in v1 |
| Middleware and hooks | v1 | Model, tool and agent-step hooks |
| Tool interrupts and human approval | v1 | Server-authoritative policy |
| Prompt templating | later | Dart string builders in v1; a template format later |
| MCP client | v1 | Own client over HTTP and stdio plus a `dart_mcp` backed session; servers treated as untrusted |
| Embeddings and retrieval | v1 | Local and cloud embedders, native index, web fallback |
| Multimodal input | v1.x | Images for cloud providers first; local vision later |
| Tracing (OpenTelemetry-compatible) | v1 | Own span model, redacted by default, OTel exporter later |
| Evaluation and test utilities | v1 (test kit), later (evaluators) | Mock provider, fixture recorder and replayer |
| Flutter widgets for streaming UI | later | Phase 5 |
| CLI and dev tooling | later | Phase 5, Dart-native inspector |
| Realtime voice, media generation | never in v1 | Revisit after 1.0 |
| Genkit wire-protocol compatibility | never | Independent design by decision; protocol used only as reference |

## 7. Licensing and attribution notes

- Genkit Dart is Apache-2.0. Nothing was copied. Ideas, protocol knowledge and
  lessons are not subject to attribution. If any Genkit code, test fixture or
  sample is ever adapted, Apache-2.0 section 4 requires keeping its license
  text and any NOTICE content, and marking the modified files.
- Planned native dependencies and their licenses (verified, see native facts):
  llama.cpp and ggml MIT, USearch Apache-2.0, wllama MIT (web). All are
  compatible with an MIT project. Apache-2.0 components need their license
  text and NOTICE carried in `THIRD_PARTY_NOTICES`.
- Model weights are not shipped. Their licenses (Qwen, Llama, Gemma terms)
  belong to the user; docs must say so.
- Avoid: fllama (GPL-2.0), aub_ai (AGPL-3.0), nobodywho (EUPL-1.2) as
  dependencies or code sources.

## 8. Items that still need a spike or a check

- Stripped size of libllama plus ggml per Android ABI and per iOS slice.
- llama.cpp Vulkan on Android (not documented as supported).
- Whether a package that declares a build hook still builds for Flutter web
  without errors (llamadart and flutter_edge_ai suggest yes).
- wllama token-count API name (grammar, embeddings and abort are confirmed).
- Apple review position on downloading model weights after install.
- Final web status of the Chrome Prompt API.

## 9. Name

Chosen: `jackdaw`. Vetted bird names, all free on pub.dev (root, `_core`, `_flutter` and provider
suffixes) and on GitHub under `Crdzbird`. Not a legal trademark search.

| Rank | Name | Meaning | Collisions |
|---|---|---|---|
| 1 | corax | Latin species name of the raven, a planner and problem solver | None in AI; a Java analyzer and a keyboard app on GitHub |
| 2 | kea | New Zealand parrot known for tool use and puzzle solving | keajs (React state), ISC Kea DHCP; none in AI |
| 3 | jackdaw | Corvid that collects and remembers (agent memory) | A security tool and a game editor; none in AI |

Rejected because taken on pub.dev or colliding with AI products: raven, corvid,
magpie, wren, starling, osprey, avian, roost, kestrel and others (full list in
[research/names.md](research/names.md)).
