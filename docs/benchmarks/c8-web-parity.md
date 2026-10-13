# Claim C8: the same behaviour on native and web

Date: 2026-10-13. Status: met for local models.

Claim C8: the same public API and the same contract test suite pass on
Chrome (JS and Wasm builds).

## Contract suite

`languageModelContract` in `jackdaw_test` declares six tests that every
`LanguageModel` must pass:

1. a reply ends with exactly one finish event, after its text;
2. a small token limit ends the reply with the `length` reason;
3. a response schema yields JSON that validates against it;
4. tool calls carry unique ids and arguments valid for the tool's schema,
   and end with the `toolCalls` reason;
5. cancelling a reply after its first event works, and the next request
   still completes;
6. `generate` never throws synchronously, even for an empty request.

A `prepare` hook lets fakes script each case; real models need none.

## Results

| Model | Platform | Backend | Result |
|---|---|---|---|
| `LocalModel`, Qwen2.5-1.5B-Instruct Q4_K_M | Dart VM, macOS | llama.cpp, Metal | 6/6 |
| `WebLocalModel` | Chrome, dart2js | fake wllama | 6/6 |
| `WebLocalModel` | Chrome, dart2wasm | fake wllama | 6/6 |
| `ScriptedModel` | VM and Chrome | scripted | 6/6 |

Both local models share one prompt format, one grammar compiler and one
tool-call decoder from `package:jackdaw`, so the contract checks the
native and web transports around the same core.

## Real browser

`packages/jackdaw_web/example/web/tools.dart`, compiled with dart2js and
served next to Qwen2.5-1.5B-Instruct Q4_K_M, ran in Chrome with wllama
3.8.1: the agent called `get_weather` with `{city: Lima}` and answered
"The weather in Lima is currently sunny with a temperature of 21 degrees
Celsius." from the tool's result. `example/web/embed.dart` earlier showed
browser embeddings equal to native ones (cosine 1.0).

## Open

The contract runs against the real wllama only by hand, through the
example pages; CI uses the fake.
