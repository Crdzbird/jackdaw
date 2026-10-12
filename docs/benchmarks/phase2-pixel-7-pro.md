# Phase 2 benchmarks: Pixel 7 Pro

Measured 2026-10-12 on the reference device from ADR 0001.

| Item | Value |
|---|---|
| Device | Google Pixel 7 Pro (cheetah), Tensor G2, 12 GB RAM, Android 17 |
| Build | Flutter 3.47.7 profile build, Dart 3.13.5, NDK r28.2, arm64-v8a |
| Native core | libjackdaw 0.1.0 on llama.cpp v0.6.0, CPU backend, 4 threads, `armv8.2-a+dotprod+fp16` |
| Model | Qwen2.5-1.5B-Instruct Q4_K_M GGUF, 1,117,320,736 bytes, SHA-256 `6a1a2eb6...e9407e` |
| Harness | `apps/jackdaw_bench`, run with `tool/run_android.sh` |

## Results against the claims

| Claim | Target | Measured | Status |
|---|---|---|---|
| C1 structured output, 50-case slice | at least 99% schema-valid | 50/50 (100%) with the grammar | Met |
| C3 cancel latency | p95 under 100 ms | p50 7.1 ms, p95 8.1 ms, max 12.5 ms (20 runs) | Met |
| C4 memory over 100 load and dispose cycles | within 5% of baseline | 301.7 MB to 308.7 MB, +2.3%, flat after cycle 20 | Met |
| C5 time to first token, turn 20 vs turn 2 | at most 1.2x | 391 ms to 527 ms, 1.35x | Missed |
| C6 UI frames during inference | no inference frames on the UI thread | not measured yet | Open |
| C12 packaging | no toolchain, 16 KB pages, no ggml exports | 16 KB and exports verified for 3 ABIs; prebuilt download not yet released | Partly met |

## Structured output (C1)

Ten topics in five schema shapes (flat, enum plus number, string array,
nested object, array of objects), `maxOutputTokens: 256`, greedy decoding.

| Condition | Schema-valid |
|---|---|
| Grammar from `GbnfCompiler` plus schema instruction | 50/50 |
| Schema instruction only, strict `jsonDecode` | 42/50 |
| Schema instruction only, after stripping text around the JSON | 49/50 |

The suite ran in 479 s for 100 generations. The full 200-case suite from the
gap analysis is still to be written.

## Prefix reuse (C5)

A 20-turn chat, 24 output tokens per turn. Reused prompt tokens grow from 52
at turn 2 to 785 at turn 20 (of 807). Time to first token per turn, in ms:

```text
565 391 369 386 393 410 424 432 431 467 465 474 461 488 491 487 511 504 516 527
```

Without reuse, turn 20 would reprocess 807 tokens at the measured 67 prompt
tokens per second, about 12 s. The remaining growth is attention over a
longer context, not reprocessing, so the 1.2x target is not reachable on CPU
by caching alone. See ADR 0001, Phase 2 results.

## Throughput

| Metric | Value |
|---|---|
| Model load (mmap, cold page cache after install) | 1.9 to 2.0 s |
| Model load (warm) | 0.5 s |
| Prompt processing | 67 tokens/s |
| Generation | 13.0 tokens/s |
| First token, 16-token prompt | 238 ms |

Before enabling dot-product kernels the same device measured 26 prompt
tokens/s and 11.4 generated tokens/s, and turn-2 first token took 1,220 ms.

## Library sizes (stripped)

| Target | Size | 16 KB aligned | Exported symbols |
|---|---|---|---|
| android arm64-v8a | 4,326,024 bytes | yes | 14, all `jackdaw_*` |
| android armeabi-v7a | 3,086,676 bytes | yes | 14, all `jackdaw_*` |
| android x86_64 | 4,842,632 bytes | yes | 14, all `jackdaw_*` |
| macos arm64 (Metal shaders embedded) | 9,021,248 bytes | n/a | 14, all `jackdaw_*` |

## Reproduce

```bash
apps/jackdaw_bench/tool/run_android.sh <device-id> ~/.cache/jackdaw/models/qwen2.5-1.5b-instruct-q4_k_m.gguf
```

A comma separated third argument selects benchmarks:
`throughput,cancel,prefix,structured,memory`.
