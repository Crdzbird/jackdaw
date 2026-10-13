# ADR 0001: v1 scope, native core boundary and web strategy

- Status: Accepted 2026-10-12
- Date: 2026-10-12
- Owner: Crdzbird (personal GitHub account)
- License of the project: MIT
- Name: `jackdaw` (chosen; repository folder stays `genkit-ai-bird` until the
  owner renames it)
- Inputs: [gap analysis](../gap-analysis.md), [research notes](../research/)

## Context

The goal is a Dart and Flutter framework for building AI agents, backed by a
C++ core, that beats the current options on measurable points. The gap analysis
shows three facts that shape every decision below:

1. On-device inference alone no longer differentiates. llamadart and
   flutter_edge_ai already ship llama.cpp or LiteRT-LM with prebuilt binaries.
2. What nobody ships is an agent framework in which local and cloud models
   share one runtime with reliable structured output and tool calls, exact
   budgets, local RAG, a security policy layer, and the same behaviour on web.
3. The recurring failures of existing native packages are lifecycle and
   packaging failures (cancel, memory, isolate blocking, toolchains, 16 KB
   pages, symbol clashes), not missing features.

User decisions already taken: on-device inference is in v1; Flutter web must
work at launch; the design is independent of Genkit (its protocol is reference
only); v1 providers are Gemini, OpenAI, Anthropic, Ollama, local, plus
OpenAI-compatible endpoints for the long tail; MIT; personal GitHub.

## Decision 1: v1 differentiators

Three pillars need native code. Two pillars are pure Dart and ship in v1
because an agent framework without them is unsafe or unreliable.

| Pillar | What it is | Native? | Claims (gap analysis section 5) |
|---|---|---|---|
| P1 Local inference engine | llama.cpp behind our own C ABI: worker thread, cooperative cancel, KV prefix reuse across turns, memory accounting, exact tokenization, embeddings | Yes | C3, C4, C5, C6, C12 |
| P2 Constrained generation | JSON Schema compiled to a GBNF grammar in Dart (shared by native and web), applied by the native sampler; tool calls forced through a grammar we own, so no per-family parser | Sampler yes, compiler no | C1, C2 |
| P3 Local vector index | Exact int8 index behind the same C ABI, persisted to disk; retriever API in Dart (amended in Phase 4: USearch HNSW is deferred until an index needs more than about a million vectors) | Yes | C7 |
| P4 Security layer | Server-authoritative tool policy, approval hooks, taint marking of tool and retrieval output, egress checks on tool arguments, redaction by default | No | C10 |
| P5 Durable agent runtime | Event-sourced step log, checkpoint per step, idempotency keys for tools, resume after process kill | No | C11 |

Cross-cutting claims C8 (web parity) and C9 (fully offline) apply to all five.

Deferred: fast streaming parsers in C++ (Dart is fast enough for SSE and
NDJSON), C++ JSON Schema validation (Dart validator is portable and offline),
C++ security heuristics (pattern matching does not need native speed),
deterministic replay of model output (later, builds on P5).

## Decision 2: what stays in Dart and what goes to C++

Rule: code goes to C++ only when Dart cannot do it at all (running a model,
GPU backends) or cannot do it within budget (ANN search over 100k vectors,
tokenizing with the model's own vocabulary). Everything else is Dart, so it
runs on web without a second implementation.

| Concern | Lives in | Reason |
|---|---|---|
| Model execution, sampling, grammar sampler, KV cache | C++ (llama.cpp) | Not possible in Dart |
| Tokenize and detokenize for local models | C++ (llama.cpp) | Needs the GGUF vocabulary; exactness |
| Embedding computation for local models | C++ (llama.cpp) | Same model runtime |
| Vector index build, search, persistence | C++ (our int8 index) | Speed and memory: a quarter of float storage |
| Worker threads, cancel flag, token ring buffer | C++ (our shim) | Must not block the UI isolate |
| JSON Schema to GBNF compiler | Dart | Pure string work; shared with web |
| JSON Schema validator and repair | Dart | Portable, offline, used for cloud too |
| HTTP, SSE, NDJSON, retries, cancellation | Dart | `package:http` is web-safe and adequate |
| Provider adapters | Dart | Web-safe |
| Agent loop, budgets, sessions, middleware | Dart | Logic, not compute |
| Security policy, redaction, injection heuristics | Dart | Logic, must also run on web |
| Exact flat vector search fallback | Dart | Web fallback; `Float32List` is enough for small sets |

## Decision 3: native core shape

One dynamic library per target, `libjackdaw`, built from:

- our C++20 shim (`native/src`), the only code that exports symbols;
- llama.cpp and ggml pinned to a release tag (versioned releases exist since
  v0.2.0; we pin, never track master);
- USearch pinned to a release tag.

Rules for the C ABI (`native/include/jackdaw.h`):

- Opaque handles only (`jackdaw_model*`, `jackdaw_session*`, `jackdaw_index*`), each
  with explicit create and destroy functions.
- Every function returns an `int32_t` status code. A thread-local
  `jackdaw_last_error()` returns a message owned by the library and valid until
  the next call on that thread.
- No C++ types, exceptions or STL containers cross the boundary. Every
  exported function is `noexcept` and wraps its body in a catch-all that maps
  to a status code.
- Buffers are caller-owned unless documented. Where the library must return
  variable-size data (token text, search results) it hands out a handle plus a
  matching `jackdaw_*_free` function.
- Every function documents its thread-safety. Handles are not shared across
  threads unless the header says so.
- An ABI version function (`jackdaw_abi_version`) is checked by Dart at load
  time; a mismatch fails loudly instead of crashing later.
- Only `jackdaw_*` symbols are exported: `-fvisibility=hidden`, a linker version
  script on ELF and an exported-symbols list on Mach-O. ggml and llama
  symbols stay internal, which avoids the collisions seen in
  [fllama#25](https://github.com/Telosnex/fllama/issues/25).
- Bindings are generated by `ffigen` against `jackdaw.h` only, never against
  `llama.h`, so llama.cpp API churn stays inside the shim.

## Decision 4: async bridge

- Each model session owns a native worker thread. Dart never calls a blocking
  function on the UI isolate.
- Long operations (model load, generation, index build) start on the worker
  and report through a `NativeCallable.listener` callback (stable since Dart
  3.1, void return, any thread). The Dart side feeds a `StreamController`,
  so tokens arrive as a `Stream<String>` and progress as a `Stream<double>`.
- Token text is written to a native ring buffer; the callback carries the
  request id and a slot index. Dart copies the bytes and releases the slot.
  This avoids per-token allocation and keeps pointers valid until Dart has read
  them, as the listener contract requires.
- Cancellation sets an atomic flag checked before every decode step. The
  `Stream` subscription's `onCancel` triggers it, so cancelling in the UI
  stops native work (claim C3).
- Backpressure: if Dart has not drained the ring buffer, the worker waits on a
  condition variable instead of dropping tokens or growing memory.
- Not used: `NativeCallable.isolateGroupBound` and shared isolates. Both are
  experimental or flag-gated as of Dart 3.14 beta.

## Decision 5: packaging and distribution

- Mechanism: Dart build hooks (`hook/build.dart`) with `package:hooks` and
  `package:code_assets`, stable since Dart 3.10 (Flutter 3.38).
- Default path: the hook downloads a prebuilt `libjackdaw` for the exact target
  from this project's GitHub Releases, verifies a SHA-256 hash that is pinned
  in Dart source, and emits a `CodeAsset` with `DynamicLoadingBundled`. No C++
  toolchain is needed by users (claim C12). The official example uses MD5; we
  do not.
- Source path: a `build_from_source` user define builds with CMake for
  contributors and CI. It is not the default because building llama.cpp in a
  hook needs the experimental `native_toolchain_cmake` and a full toolchain.
- Binaries are never put in the pub archive (limits: 100 MiB compressed,
  256 MiB uncompressed).
- CI produces, per release: Android arm64-v8a, armeabi-v7a and x86_64 (NDK
  r28 or newer, 16 KB aligned, checked with `readelf`); iOS device arm64 and
  simulator arm64 and x86_64 (same file name across slices, no fat Mach-O);
  macOS arm64 and x86_64 as separate files; Windows x64; Linux x64. Windows and
  Linux arm64 follow later.
- Static linking is not available in the SDK, so the core is a dynamic
  library; Flutter wraps it in a framework on Apple platforms.
- Supply chain: binaries are built only by CI from a tagged commit, with an
  SBOM and build provenance attached to the release. The hash table in Dart
  source is generated by the release job and reviewed in the release PR.
- Model weights are never bundled. A downloader with resumable transfers and
  hash checks ships in v1; docs cover licensing of weights.

## Decision 6: web strategy

Build hooks cannot produce Wasm or JS assets, and Flutter web skips them, so
the web needs separate backends behind the same public API.

| Feature | Native backend | Web backend | Label |
|---|---|---|---|
| Cloud providers | Dart HTTP | Same Dart HTTP | Identical |
| Local inference | `libjackdaw` (llama.cpp) | wllama (llama.cpp compiled to Wasm, WebGPU when present) through `dart:js_interop` | Identical API, slower; COOP and COEP headers needed for threads |
| Constrained output | GBNF from the Dart compiler | Same GBNF passed to wllama's `grammar` option | Identical |
| Exact local token counts | `libjackdaw` | wllama tokenizer (API name to verify) | Identical |
| Local embeddings | `libjackdaw` | wllama `createEmbedding` | Identical |
| Vector index | USearch, persisted, memory-mapped | Pure-Dart exact search, in memory, export and import as bytes | Documented size limit on web; IndexedDB persistence in v1.x |
| Sessions | File store | In-memory store in v1, IndexedDB store in v1.x | Documented |
| GPU acceleration | Metal, CPU everywhere; Vulkan or OpenCL on Android after the spike | WebGPU in Chrome, Safari 26, Firefox on Windows | Native-only details documented |

Further web rules:

- Backends are chosen by conditional imports on `dart.library.js_interop`
  and `dart.library.ffi`. No `dart:html`, `package:js` or `dart:js_util`, so
  every package is Wasm-ready and earns full pana platform points.
- The wllama runtime files and model files are hosted by the app (web assets
  or a CDN the app chooses); we provide a loader and docs. Model files above
  2 GB must be split, which wllama supports.
- Cloud provider keys in a browser are a development convenience only. Docs
  say so plainly, and a relay pattern (Decision 9) is the production answer.
- The contract test suite runs in Chrome for both the JS and the Wasm build
  (claim C8).

## Decision 7: package layout

Sibling packages in one repository, joined by a Dart pub workspace (root
`pubspec.yaml` with `workspace:`), no Melos. Plain `path:` dependencies were
tried first and dropped because pub rejects them in publishable packages;
workspace members depend on each other with normal version constraints.

| Package | Contents | Platforms |
|---|---|---|
| `jackdaw` | Messages, model interface, schema builder, validator, GBNF compiler, tool loop, agent runtime, budgets, sessions, middleware, policy, tracing | All |
| `jackdaw_native` | `hook/build.dart`, ffigen bindings, Dart wrappers over `libjackdaw` | Native only (labelled) |
| `jackdaw_local` | Public local model, embedder and vector index API; picks the native or the wllama backend by conditional import | All |
| `jackdaw_gemini`, `jackdaw_openai`, `jackdaw_anthropic`, `jackdaw_ollama` | Provider adapters; `jackdaw_openai` also covers OpenAI-compatible endpoints | All |
| `jackdaw_test` | Mock provider, fixture recorder and replayer, contract test suite | All |
| `native/` (not a Dart package) | C++20 shim, CMake, tests, fuzzers, pinned third-party sources | Build only |

Later: `jackdaw_flutter` (streaming chat widgets), `jackdaw_mcp`, `jackdaw_otel`,
`jackdaw_relay`.

## Decision 8: providers

- Own thin adapters over `package:http` for Gemini, OpenAI, Anthropic and
  Ollama, instead of depending on the `ai_clients_dart` SDKs. Reasons: the
  framework must own SSE parsing, per-request cancellation, Retry-After,
  redaction and error mapping (Genkit gap rows 13 and 20 come from not owning
  this layer), every adapter takes an injected `http.Client`, and dependency
  count stays low. Cost: we track API changes for four providers ourselves.
- Native Ollama adapter exposes `num_ctx`, `top_k` and model discovery with a
  short timeout (gap row 12).
- The OpenAI-compatible mode covers OpenRouter, Groq, DeepSeek, xAI, Mistral,
  LM Studio, vLLM and corporate gateways in v1.
- v1.x: Anthropic prompt caching, OpenAI Responses API. Later: Azure OpenAI,
  Bedrock, Vertex.
- Every adapter passes the same contract suite against recorded fixtures. No
  live keys in CI.

## Decision 9: protocol

- v1 is in-process: agents run where the app runs (device, desktop, browser or
  a Dart server).
- v1.x adds `jackdaw_relay`: a small versioned HTTP plus SSE protocol so a
  Flutter client can drive an agent on a server and keep keys off devices.
  Informed by Genkit's envelope and SSE framing, but not compatible by design.
  It adds what Genkit lacks: request ids, a cancel endpoint, resumable streams
  by event offset, and server-side tool approval only.

## Decision 10: toolchain floors and conventions

- Dart SDK `^3.13.0`, the version CI actually tests (stable 3.13.5 and
  beta). Hooks need only 3.10, so the floor can drop once a CI job proves it;
  very_good_analysis 11 and the 3.13 constructor syntax set it for now.
- Dart: `very_good_analysis` with infos fatal, 100% line coverage, dartdoc on
  every public member, sealed classes for messages, parts and results, no
  `dynamic` in public signatures. House rules: one class per file, at most 100
  lines per file after `dart format`, no `else` branches, `final class` by
  default, `const factory` redirects for public constructors, no unawaited
  futures, no inline `//` comments.
- C++: C++20, CMake, clang-tidy, warnings as errors, ASan and UBSan and TSan
  jobs, libFuzzer targets for every input parser we own (ABI argument
  decoding, index file loader), GoogleTest or Catch2 unit tests.
- Benchmarks for claims C1 to C7 live in the repository and run on demand and
  before each release.

## Security baseline

Threat model (full version goes in `SECURITY.md` before the first release):

| Threat | Control in v1 |
|---|---|
| Prompt injection through tool output or retrieved documents | Content from tools and retrieval is typed as untrusted, wrapped in delimiters, never promoted to system role; heuristic scanner flags known patterns (documented as a heuristic, not a guarantee) |
| Tool abuse and privilege escalation | Default-deny policy per tool, argument constraints, approval required for side-effecting tools, approval decided server-side only |
| Exfiltration through tool arguments | Egress policy (host allowlist for URL arguments), secret detector on outgoing arguments |
| Secrets in logs and traces | `Secret` type with redacted `toString`, trace redaction on by default, canary tests (C10) |
| Malicious MCP servers | MCP is v1.x; servers will be untrusted tool sources under the same policy |
| Supply chain of native code | CI-only builds, pinned sources, SHA-256 pinned downloads, SBOM, provenance |
| Memory safety in native code | Small shim surface, sanitizers in CI, fuzzing of every owned parser, bounds checks at the ABI edge |
| Keys in client apps | Documented as development only; relay in v1.x |

## Alternatives considered

| Alternative | Why not |
|---|---|
| Pure Dart only, local inference via llamadart | Inherits its lifecycle and packaging decisions, cannot guarantee claims C3 to C6 or symbol hiding; no native vector index |
| Contribute to Genkit Dart | Maintainers declined first-party on-device and native Ollama; Dart waits on JS designs |
| C++ for HTTP, SSE and JSON | No benefit over Dart, breaks web, adds attack surface |
| Rust core | Adds a second native toolchain for contributors; the C++ ecosystem (llama.cpp, USearch) is the one we need |
| LiteRT-LM instead of llama.cpp | Narrower model coverage, no GBNF grammar sampler; may become a second engine later |
| Build from source by default | Requires toolchains on every user machine, the top complaint in the survey |
| sqlite-vec instead of USearch | Pre-v1 with breaking changes expected; USearch has a stable C API and Wasm support |

## Consequences

- Positive: one native library with a narrow ABI; web parity by design; the
  measurable claims give a clear definition of done; llama.cpp churn is
  contained in the shim.
- Negative: we own release engineering for about ten binary targets; four
  provider adapters to maintain; web local inference depends on app-side
  hosting and cross-origin isolation headers.
- Risks: llama.cpp API changes (pinned and shimmed); binary size on mobile
  (measured in the spike); llamadart's release velocity (compete on the agent
  layer and measured reliability, not on engine breadth); Apple review of model
  downloads (to be checked before the first iOS release).

## Phase 2 spike: exit criteria

End to end on one platform, Android arm64 on the reference device (Pixel 7
Pro), developed on
macOS where the same code runs under `dart test`:

1. `hook/build.dart` fetches and verifies a CI-built `libjackdaw`; a fresh Flutter
   app runs it with no C++ toolchain installed.
2. Stream tokens from the reference model; cancel within 100 ms at p95 (C3).
3. Structured output through the Dart GBNF compiler on a first 50-schema slice
   of the C1 suite, at least 99% valid.
4. RSS stable over 100 load and dispose cycles (C4).
5. Measured stripped binary size per ABI, recorded in the ADR.
6. Benchmarks checked in and reproducible.

If criteria 2 to 4 fail, revisit Decision 1 before building more.

## Resolved questions

- Q1 Reference device: Google Pixel 7 Pro. It is 64-bit only, so armeabi-v7a
  is tested on an emulator or a second device.
- Q2 Name: `jackdaw`. A trademark search is still advised before the first
  publish.
- Q3 Providers: own thin adapters over `package:http` (Decision 8 stands).
- Q4 Android ABIs: ship both 64-bit and 32-bit (arm64-v8a, armeabi-v7a, plus
  x86_64 for emulators).
- Q5 Repository: keep `genkit-ai-bird` for now; the owner renames it later.

## Phase 2 results (2026-10-12)

Measured on the reference device; details in
[benchmarks/phase2-pixel-7-pro.md](../benchmarks/phase2-pixel-7-pro.md).

| Exit criterion | Status |
|---|---|
| 1. Hook fetches a verified CI-built library; fresh app needs no toolchain | Hook, SHA-256 check and tag-gated release workflow are done and tested against a local server. No release is published yet, so apps still use `build: source` |
| 2. Stream tokens; cancel p95 under 100 ms (C3) | Met: p95 8.1 ms |
| 3. 50-schema slice at least 99% valid | Met: 50/50 with the grammar, 42/50 without |
| 4. RSS stable over 100 load and dispose cycles (C4) | Met: +2.3% |
| 5. Stripped size per ABI | arm64 4.3 MB, armeabi-v7a 3.1 MB, x86_64 4.8 MB, macOS arm64 9.0 MB |
| 6. Benchmarks checked in and reproducible | Met: `apps/jackdaw_bench` |

Decisions taken during the spike:

- Android arm64 is built for `armv8.2-a+dotprod+fp16`. Without dot-product
  kernels prompt processing was 2.6x slower (26 vs 67 tokens/s). The cost is
  that phones with only ARMv8.0 cores (for example Cortex-A53-only devices)
  are not supported. Shipping runtime-selected CPU variants
  (`GGML_BACKEND_DL`) would remove that limit and is a Phase 3 candidate.
- armeabi-v7a is built with `GGML_LLAMAFILE=OFF`, because llama.cpp's
  llamafile kernels need fp16 intrinsics that ARMv7 lacks.
- Requests on one native session run strictly one after another. A request
  waits until the previous one, cancelled or not, has stopped natively, so
  cancel-and-resend can never hit `JACKDAW_ERR_BUSY`.
- For local models the response schema is enforced by the grammar and also
  described in the system message, so the model knows what fields mean.
- iOS and Windows builds move to Phase 3, alongside the first release.
- Fuzzing moves to Phase 6. Note for that work: grammars are compiled from
  schemas, and schemas can come from untrusted tool sources such as MCP
  servers, so llama.cpp's GBNF parser is reachable from outside input.

Open for sign-off:

- C5 as written (turn-20 first token within 1.2x of turn 2) was missed at
  1.35x. The growth is attention cost over a longer context, not
  reprocessing; caching cut turn-20 from about 12 s to 527 ms. Proposed
  restatement: "turn-20 time to first token within 1.5x of turn 2 and at
  least 10x faster than reprocessing the full prompt".
- C6 (no UI-thread frames during inference) is not measured yet; it needs a
  Flutter frame-timing harness and is planned with the widgets in Phase 5.

## Phase 3 progress (2026-10-13)

Delivered:

- Providers: `jackdaw_anthropic` (Messages API), `jackdaw_gemini`
  (`generateContent`) and `jackdaw_ollama` (native `/api/chat`), next to
  `jackdaw_openai`. Wire formats were taken from the official documentation;
  Ollama's contract tests replay responses recorded from Ollama 0.33.3 and an
  opt-in test runs an agent against a live server.
- Core: `ReasoningPart` and `ToolCallPart.providerData` carry provider data
  that must come back unchanged (Claude thinking blocks, Gemini thought
  signatures). Agent turns keep parts in the order the model produced them.
  `HttpTransport` gives every provider the same streaming, abort and error
  mapping, and errors sent inside a stream fail it with `ProviderException`.
- Web: `jackdaw_web` runs GGUF models in the browser through wllama 3.8's
  OpenAI-compatible API, reusing the OpenAI wire helpers and the shared GBNF
  compiler. Verified end to end in Chrome with Qwen2.5-1.5B (streaming text
  and schema-valid JSON). The wllama module and wasm URLs are explicit
  arguments; nothing is fetched implicitly.
- iOS: verified on the simulator (streaming, JSON mode, cancel in 4 ms).
  Simulator builds are CPU-only (`GGML_METAL=OFF`), because llama.cpp's Metal
  backend produces invalid output on the simulator's virtual GPU; device
  builds keep Metal.
- Linux: llama.cpp is now a SYSTEM dependency so its headers cannot trip our
  warning flags, and `<algorithm>` is force-included for the llama target to
  work around a missing include in v0.6.0 under libstdc++. CI gains an
  explicit GCC job.
- Windows: builds in CI with MSVC. The first CI build showed that llama.cpp
  v0.6.0 does not compile as C++20 under MSVC (`u8` literals become
  `char8_t`), so llama.cpp now builds as C++17 and only jackdaw's own
  targets use C++20.

Known limitations recorded here:

- Browser coverage for `jackdaw_web` first crashed in package:test because
  the fake wllama module was a `data:` URL. Serving it as a real file next
  to the tests fixed that; the package is at 100% line coverage and CI
  enforces it.
- Grammar-constrained decoding used to cost about 2.5x in tokens per second
  on CPU, because the grammar sampler scored the whole vocabulary. Fixed: the
  grammar now checks only the sampled token and rescores the vocabulary only
  on rejection, so constrained and free decoding run at the same speed
  (75.2 vs 75.0 tok/s on CPU), with 50/50 schema-valid answers on the Pixel.
- Debug (JIT) iOS builds started without the Flutter tool attached do not
  load the model; profile and release builds are the supported way to
  measure.

- Prebuilt release: `native-v0.1.0-dev.1` was published by CI from a tagged
  commit with seven libraries and `SHA256SUMS`; the hashes are pinned in
  `prebuilt_hashes.dart`. Phase 2 exit criterion 1 is now met: a fresh
  Flutter app built with `cmake` and `ninja` blocked on `PATH` downloaded the
  verified library and produced schema-valid JSON on the Pixel 7 Pro, and a
  fresh Dart app did the same on macOS.

- Older Android phones: the library reports the CPU features it was built
  for (`jackdaw_cpu_requirements`, ABI version 2). On Android, `LocalModel`
  compares them with `/proc/cpuinfo` and throws a clear `UnsupportedError`
  instead of crashing on an illegal instruction. Apps that target ARMv8.0
  phones set the user define `android_cpu: baseline`, which selects an
  ARMv8.0 build, prebuilt as `android-arm64-baseline`. Choosing kernels at
  runtime (`GGML_BACKEND_DL`) was rejected: it splits the library into
  several files and exports ggml symbols, undoing the single-library design
  and symbol isolation.
- iOS: device and simulator libraries are in the release matrix, built for
  iOS 15.0; macOS libraries now target macOS 12.0, matching Flutter's app
  templates.

Phase 3 closed with release `native-v0.1.0-dev.2`: eleven libraries,
including iOS and the Android baseline build, all pinned by SHA-256. With
`cmake` and `ninja` blocked, a fresh app on the iOS simulator downloaded the
pinned library and produced schema-valid JSON, as earlier on Android and
macOS.

## Phase 4 progress (2026-10-13)

Done, each with tests at 100 percent line coverage on the VM and passing on
Chrome with dart2js and dart2wasm:

- Tool policies and human approval. `ApprovalPolicy` is the default and
  asks only for tools marked `requiresApproval`; `RulePolicy` denies every
  tool it does not list and supports argument guards. Only calls that are
  pending approval can be decided, so a client message cannot approve a
  denied call (claim C10, first half).
- Durable sessions. Every step is an append-only `SessionRecord` in a
  `SessionStore` (in memory, or JSON lines on disk in `io.dart`). A harness
  kills the process at each of the nine writes of a two-tool turn and
  resumes; no non-idempotent tool runs twice (claim C11). Tools get their
  call id as an idempotency key through `ToolContext.callId`.
- Sub-agents. `delegateTo` exposes an agent as a tool, with a depth limit
  carried in a zone.
- Context budgets. `ContextBudget` trims the oldest turns before each model
  call and keeps the last user message; the journal keeps everything.
- Tracing. Agents emit `invoke_agent`, `chat` and `execute_tool` spans with
  OpenTelemetry GenAI attribute names through a `Tracer` interface. Content
  is attached only when `traceContent` is on. Every tracer is wrapped so
  common credential shapes are removed, and `RedactingTracer` also removes
  registered `Secret` values. A canary test puts a secret in instructions,
  user text, tool arguments, tool output, tool errors and model errors and
  checks that it never reaches a span (claim C10, second half).
- Egress checks. `EgressPolicy` refuses a tool call whose arguments carry
  a registered secret or a credential shape, before the tool runs.
- Retrieval. `Embedder` and `VectorIndex` interfaces, `FlatVectorIndex` in
  pure Dart for the web, `TextChunker`, `Retriever`, and `retrievalTool`,
  whose output tells the model that passages are data, not instructions.
  Embedders for OpenAI, Gemini and Ollama.
- On-device retrieval. ABI version 3 adds `jackdaw_embedder_*` (llama.cpp
  embeddings with the model's pooling, mean pooling for decoder models) and
  `jackdaw_index_*`. `NativeEmbedder` and `NativeVectorIndex` wrap them.
  `WebEmbedder` in `jackdaw_web` uses wllama `createEmbedding`, so the web
  pairs it with `FlatVectorIndex`.

### Amendment to P3: exact search instead of HNSW

The plan was USearch HNSW. Measuring first showed that an exact scan over
int8 codes meets claim C7 on the Pixel 7 Pro with a p95 of 2.7 ms at 100k
vectors of 384 dimensions, recall@10 of 0.97 to 0.99, and an open time of
80 to 116 ms (`docs/benchmarks/c7-vector-index.md`). An exact index has no
build parameters to tune, no recall cliff on updates, needs no new
dependency, and deletes are exact. Scan time grows linearly, so HNSW
becomes worth its cost somewhere near a million vectors; that is deferred
until a user needs it.

### Still open in Phase 4

- Release `native-v0.1.0-dev.3` with ABI 3 binaries and pin their hashes;
  until then the default prebuilt download is ABI 2 and the Dart package
  refuses to load it, so only `build: source` works.
- MCP client, with servers treated as untrusted. The gap analysis plans it
  for v1.x on top of `dart_mcp` or `mcp_dart`; adding either is a new
  dependency and waits for a decision.
- A live browser run of `WebEmbedder` against real wllama; the tests use a
  fake module.

