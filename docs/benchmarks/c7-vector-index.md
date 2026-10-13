# Claim C7: local vector index

Date: 2026-10-13. Commit: the one adding this file.

Claim C7 from the gap analysis: 100k vectors of 384 dimensions, recall@10
of at least 0.95 against exact search, p95 query under 10 ms, cold open
under 200 ms, on the reference device.

## Setup

- Index: `NativeVectorIndex` from `jackdaw_native`. Vectors are scaled to
  unit length and stored as int8 codes with one float scale per row. Search
  compares the query with every row (exact up to quantization) and keeps a
  top-k heap. Saving writes a binary file and an id map, each replaced
  atomically.
- Ground truth: `FlatVectorIndex`, the exact float32 index in pure Dart.
- Data: 100,000 vectors of 384 components with a fixed seed. "Clustered"
  draws vectors around 1,000 centres with noise, which resembles real
  embeddings. "Random" is uniform noise, the hardest case for quantized
  scores because true neighbours are barely closer than everything else.
- 50 queries for recall, 500 for latency, k = 10, one thread.
- Open: `openIndex` on a background isolate, including reading the 40 MB
  index file, building the key map and decoding the id map. The file was
  just written, so it was in the page cache; a true cold read after a
  reboot adds the flash read of 40 MB.
- Runner: `apps/jackdaw_bench/lib/src/vector_bench.dart`, through
  `tool/run_android.sh <device> <model> vectors` on Android and
  `dart run tool/vector_bench.dart` on the desktop.

## Results

| Device | Data | recall@10 | p50 ms | p95 ms | add 100k ms | open ms |
|---|---|---|---|---|---|---|
| Pixel 7 Pro (arm64, dotprod build) | clustered | 0.970 | 2.63 | 2.66 | 282 | 80 |
| Pixel 7 Pro (arm64, dotprod build) | random | 0.988 | 2.65 | 2.72 | 279 | 116 |
| MacBook (Apple silicon) | clustered | 0.970 | 1.10 | 1.14 | 177 | 48 |
| MacBook (Apple silicon) | random | 0.988 | 1.17 | 1.28 | 151 | 49 |

The baseline Android build (`android_cpu: baseline`, plain ARMv8 without
dotprod, for older phones) gives the same numbers on the Pixel: p95 2.66 ms
clustered and 2.72 ms random, open 86 and 119 ms. The index code is
compiled without CPU-specific flags in both builds, so the result holds for
any 64-bit ARM phone with NEON, scaled by its core speed.

All three targets are met on the reference device, with margin: p95 is a
quarter of the budget and open time is under half of it.

## Memory

The index holds 384 + 12 bytes per vector, about 40 MB for 100k vectors,
against 154 MB for float32 storage.

## What changed during the measurement

The first version of `jackdaw_index_load` read the file through a stream
iterator one character at a time and took 180 ms for the 40 MB file on the
desktop. Reading straight into the final buffers brought it to 20 ms. The id
map moved from a JSON object keyed by strings to two parallel arrays, which
cut decoding from 41 ms to 31 ms.

## Embedding check

`NativeEmbedder` with all-minilm (33M, BERT) produces vectors with cosine
1.00000 against Ollama 0.33.3 running the same GGUF file, so pooling and
normalization match the reference implementation.
