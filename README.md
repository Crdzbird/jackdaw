# jackdaw

Agent framework for Dart and Flutter with a C++ core for on-device work.
Pre-release; see [docs/adr/0001-scope-and-architecture.md](docs/adr/0001-scope-and-architecture.md)
for scope and [docs/gap-analysis.md](docs/gap-analysis.md) for the reasoning.

## Packages

| Package | Purpose | Platforms |
|---|---|---|
| [jackdaw](packages/jackdaw) | Messages, schemas, tools, agent loop, SSE | All, including web |
| [jackdaw_openai](packages/jackdaw_openai) | OpenAI and OpenAI-compatible provider | All, including web |
| [jackdaw_anthropic](packages/jackdaw_anthropic) | Claude through the Messages API | All, including web |
| [jackdaw_gemini](packages/jackdaw_gemini) | Gemini through generateContent | All, including web |
| [jackdaw_ollama](packages/jackdaw_ollama) | Native Ollama `/api/chat` | All, including web |
| [jackdaw_native](packages/jackdaw_native) | On-device GGUF inference through the C++ core | Native only; verified on Android and macOS so far |
| [jackdaw_test](packages/jackdaw_test) | Scripted model for tests | All, including web |

## Development

The packages form a Dart pub workspace; run `dart pub get` once at the root.

```bash
dart pub get
```

Checks that CI runs for every package:

```bash
./tool/check_house_rules.sh
```

```bash
cd packages/jackdaw && dart test --coverage-path=coverage/lcov.info --coverage-package='^jackdaw$' && ../../tool/check_coverage.sh coverage/lcov.info
```

```bash
cd packages/jackdaw && dart test -p chrome && dart test -p chrome --compiler dart2wasm
```

## License

MIT. See [LICENSE](LICENSE).
