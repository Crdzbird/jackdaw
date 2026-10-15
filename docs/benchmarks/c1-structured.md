# Claim C1: structured output from local models

Date: 2026-10-15. Status: met on the device for three model families:
every one of the 200 answers is schema-valid with the grammar. The web
run and the comparison with Genkit are still open; see below.

Claim C1: at least 99% schema-valid structured output from the reference
model, native and web, on a checked-in suite of 200 schemas and prompts,
compared with unconstrained decoding.

## Suite

Twenty topics (bird, city, book, planet and so on) in ten schema shapes,
200 cases in all. The first five shapes are the Phase 2 slice:

1. Flat object: string, integer and boolean.
2. Enum plus number.
3. String array.
4. Nested object.
5. Array of objects.
6. Enum and three boolean flags.
7. Object nested three levels deep with an array inside.
8. Several numbers and integers.
9. Lists of pros and cons with a summary.
10. A top-level array.

Each case runs twice with `maxOutputTokens: 256` and greedy decoding:

- With the grammar: `generateJson` with a grammar compiled from the
  schema by `GbnfCompiler`, plus the schema instruction.
- Baseline: the schema instruction only. The answer is judged strictly
  (`jsonDecode` of the whole text, then the schema) and leniently (the
  text from the first `{` to the last `}`, or from the first `[` to the
  last `]`, whichever validates).

The schema validator decides in both cases. Cases:
`apps/jackdaw_bench/lib/src/structured_cases.dart` and
`structured_shapes.dart`. Runner: `dart run tool/structured_bench.dart
[--cpu] <model.gguf>` on the desktop, or `tool/run_android.sh <device>
<model> structured` on a phone.

## Results

MacBook (M3 Max), CPU only, 4 threads:

| Model | With the grammar | Baseline, strict | Baseline, lenient | Time |
|---|---|---|---|---|
| Qwen2.5-1.5B-Instruct Q4_K_M (reference) | 200/200 (100%) | 163/200 (81.5%) | 195/200 (97.5%) | 27 min |
| Llama-3.2-3B-Instruct Q4_K_M | 200/200 (100%) | 42/200 (21%) | 146/200 (73%) | 64 min |
| gemma-2-2b-it Q4_K_M | 200/200 (100%) | 20/200 (10%) | 172/200 (86%) | 83 min |

The times cover both conditions, 400 generations per model. The first
runs judged the lenient baseline from the first `{` to the last `}`
only, which cut the brackets off every top-level array; the 20 array
cases were run again per model with the corrected check, and the column
above includes them.

With the grammar no family produced an invalid answer, because the
grammar leaves no invalid output to sample. Without it the families
differ widely. Llama and Gemma mostly put other text around the JSON,
which strict parsing rejects. Even with that text removed,
27% of Llama's answers and 14% of Gemma's still fail the schema, against
2.5% of Qwen's. An app relying on instructions alone would need retries
or repair for those answers; with the grammar it needs neither.

On the Pixel 7 Pro the 50-case slice was 50/50 with the grammar (see
[phase 2](phase2-pixel-7-pro.md)); the 200-case run on the phone is next.

## Open

- Web: the browser runs the same grammar through wllama, and the C8
  contract suite passes there, but the 200 cases have not been run in
  the browser yet.
- Genkit: the comparison with Genkit plus `genkit_llamadart` needs those
  packages added to the bench, which is a new download.
- Pixel 7 Pro: the 200-case run.
