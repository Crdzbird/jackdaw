# jackdaw

An agent framework for Dart and Flutter that runs the same agent against
cloud models, models on the device and models in the browser. Pre-release.

- One `Agent` with typed tools, human approval, durable sessions that
  survive a killed process, sub-agents, context budgets and tracing.
- Cloud providers: OpenAI and compatible servers, Anthropic, Gemini and
  Ollama, through small adapters over `package:http`.
- On-device models: GGUF through a C++ core on llama.cpp, with
  grammar-constrained JSON and tool calls, cancellation within
  milliseconds and prompt reuse across turns. Prebuilt libraries for
  Android, iOS, macOS, Linux and Windows, so no C++ toolchain is needed.
- In the browser: the same local models through wllama, with the same
  prompt format, grammars and tool calling as on the device.
- Retrieval on the device: embeddings and an exact int8 vector index that
  searches 100k vectors in under 3 ms on a Pixel 7 Pro.
- Safety by default: tools from MCP servers and tool output are treated as
  untrusted, secrets are redacted from traces, and calls that would leak a
  secret can be blocked.
- Generative UI on A2UI v1.0: the agent answers with forms, cards and
  screens built from a catalog of components, held to the catalog by a
  grammar on local models and validated again on the device; what the
  user does goes back to the agent. `jackdaw_flutter` draws it, or it
  goes to genui, an a2ui_core renderer or any other UI library through a
  `UiTarget`.

The design and its reasoning are in
[docs/adr/0001-scope-and-architecture.md](docs/adr/0001-scope-and-architecture.md),
[docs/adr/0002-generative-ui.md](docs/adr/0002-generative-ui.md) and
[docs/gap-analysis.md](docs/gap-analysis.md).

## Quick start

A tool, then an agent that uses it:

```dart
final weather = Tool<String>(
  name: 'get_weather',
  description: 'Current weather for a city',
  input: const ObjectSchema(
    properties: {'city': Schema.string()},
    required: ['city'],
  ),
  decode: (json) => json['city']! as String,
  run: (city) => {'city': city, 'celsius': 21},
);

final agent = Agent(
  model: OpenAiModel(model: 'gpt-4o-mini', apiKey: Secret(apiKey)),
  tools: [weather],
);
final done = await agent.complete([Message.user('Weather in Lima?')]);
print(done.text);
```

The same agent on the device. The first run downloads and checks Qwen2.5
1.5B Instruct, about 1.1 GB; after that it needs no network:

```dart
final model = await LocalModel.download(appSupportFolder);
final agent = Agent(model: model, tools: [weather]);
```

In a Flutter app, with a session journal, tool approval and streaming:

```dart
final chat = ChatController(
  agent: Agent(model: model, tools: [weather], store: InMemorySessionStore()),
  sessionId: 'support',
);

ChatView(controller: chat);
```

The same chat with UI: the agent gets a `render_ui` tool for the A2UI
basic catalog, the surfaces it builds appear in the transcript, and
presses come back to it as messages:

```dart
final ui = UiSurfaceController(basicCatalog);
final chat = ChatController(
  agent: Agent(model: model, tools: [ui.tool()], store: InMemorySessionStore()),
  sessionId: 'support',
  ui: ui,
);
```

## Packages

| Package | Purpose | Platforms |
|---|---|---|
| [jackdaw](packages/jackdaw) | Messages, schemas, tools, the agent loop, sessions, policies, tracing, retrieval | All, including web |
| [jackdaw_openai](packages/jackdaw_openai) | OpenAI and OpenAI-compatible servers | All, including web |
| [jackdaw_anthropic](packages/jackdaw_anthropic) | Claude through the Messages API | All, including web |
| [jackdaw_gemini](packages/jackdaw_gemini) | Gemini through generateContent | All, including web |
| [jackdaw_ollama](packages/jackdaw_ollama) | Ollama's native `/api/chat` and `/api/embed` | All, including web |
| [jackdaw_native](packages/jackdaw_native) | On-device GGUF models, embeddings and vector index | Android, iOS, macOS, Linux, Windows |
| [jackdaw_web](packages/jackdaw_web) | GGUF models and embeddings in the browser through wllama | Web |
| [jackdaw_flutter](packages/jackdaw_flutter) | Chat controller and widgets, and the renderer of agent-built UI | Flutter |
| [jackdaw_a2ui](packages/jackdaw_a2ui) | Agent-built UI on any renderer built on a2ui_core | All, including web |
| [jackdaw_mcp](packages/jackdaw_mcp) | MCP client over Streamable HTTP and stdio, plus a dart_mcp backend | All; stdio on desktop |
| [jackdaw_cli](packages/jackdaw_cli) | Inspect journals and traces, print grammars, validate JSON | Desktop |
| [jackdaw_test](packages/jackdaw_test) | Scripted model and the contract suite every model must pass | All, including web |

`apps/jackdaw_bench` is a demo app and the on-device benchmark runner;
open the repository in VS Code to run it from `.vscode/launch.json`.

## Claims and evidence

The gap analysis lists twelve measurable claims, and ADR 0002 adds two
for generative UI. Their status:

| Claim | Status | Evidence |
|---|---|---|
| C1 structured output at least 99% schema-valid | Met on the device: 200/200 for Qwen, Llama and Gemma, against 10% to 81.5% without the grammar; web run open | [c1](docs/benchmarks/c1-structured.md) |
| C2 at least 98% well-formed tool calls, three model families | Met: 100% for Qwen, Llama and Gemma | [c2](docs/benchmarks/c2-tool-calls.md) |
| C3 cancel within 100 ms at p95 | Met: 8.1 ms on a Pixel 7 Pro | [phase 2](docs/benchmarks/phase2-pixel-7-pro.md) |
| C4 no memory growth over 100 load cycles | Met: +2.3% | [phase 2](docs/benchmarks/phase2-pixel-7-pro.md) |
| C5 turn 20 first token within 1.5x of turn 2 | Met: 1.35x, about 23x faster than reprocessing | [phase 2](docs/benchmarks/phase2-pixel-7-pro.md) |
| C6 no UI frames lost to inference | Streaming frames within budget; a frame at the moment of sending still runs over | [c6](docs/benchmarks/c6-frames-pixel-7-pro.md) |
| C7 100k vectors: recall@10 at least 0.95, p95 under 10 ms | Met: 0.97 to 0.99, 2.7 ms | [c7](docs/benchmarks/c7-vector-index.md) |
| C8 same contract suite on native and web | Met | [c8](docs/benchmarks/c8-web-parity.md) |
| C9 the agent loop runs offline | Met on macOS | [c9](docs/benchmarks/c9-offline.md) |
| C10 denied tools cannot be approved; secrets never reach traces | Met | tests in `packages/jackdaw` |
| C11 sessions survive a killed process without repeated effects | Met | tests in `packages/jackdaw` |
| C12 no C++ toolchain, 16 KB pages, no exported ggml symbols | Met on Android, iOS and macOS; Linux and Windows not yet checked from a fresh app | CI and [ADR](docs/adr/0001-scope-and-architecture.md) |
| C13 at least 99% of UI answers from a local model validate against the catalog | Measuring | [ADR 0002](docs/adr/0002-generative-ui.md) |
| C14 applying UI loses no frame on the reference device | Close: 11 slow frames in 20 rounds; genui 515 | [C14](docs/benchmarks/c14-ui-frames.md) |

## Development

The pure Dart packages form a pub workspace; run `dart pub get` once at the
root. `jackdaw_flutter` and the demo app use Flutter and resolve on their
own with `flutter pub get`.

```bash
dart pub get
```

House rules and the per-package checks that CI runs:

```bash
./tool/check_house_rules.sh
```

```bash
cd packages/jackdaw && dart test --coverage-path=coverage/lcov.info --coverage-package='^jackdaw$' && ../../tool/check_coverage.sh coverage/lcov.info
```

```bash
cd packages/jackdaw && dart test -p chrome && dart test -p chrome --compiler dart2wasm
```

Tests that need a model read its path from `JACKDAW_TEST_MODEL`, for
example a Qwen2.5-1.5B-Instruct Q4_K_M GGUF, and skip without it. The
offline check runs the whole agent loop with networking disabled:

```bash
./tool/check_offline.sh ~/.cache/jackdaw/models/qwen2.5-1.5b-instruct-q4_k_m.gguf
```

The C++ core lives in `native/` and builds with CMake; Dart builds it
from source when the root `pubspec.yaml` sets `build: source`, as this
repository does, and downloads pinned prebuilt libraries otherwise.

## License

MIT. See [LICENSE](LICENSE).
