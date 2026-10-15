# Fuzzing

Phase 6 fuzzes the inputs that reach native code from outside the app.

## Targets

| Target | Input | Why it matters |
|---|---|---|
| `jackdaw_grammar_fuzz` | Arbitrary text into llama.cpp's GBNF parser | Grammars are compiled from schemas, and schemas can come from MCP servers |
| `jackdaw_index_load_fuzz` | Arbitrary bytes as a vector index file | Apps open index files they may not have written |
| `jackdaw_grammar_check` | Every grammar the Dart compiler writes for 500 random schemas and the A2UI catalog | The compiler must never emit a grammar llama.cpp rejects |

The random schemas use property names and enum values with quotes,
backslashes, newlines, tabs, emoji, empty strings and tag-like text, nest
up to three levels, and include raw JSON Schema documents. Each one is
compiled on its own and as the arguments of a tool call grammar.

## Running

The targets are built with `-DJACKDAW_BUILD_FUZZERS=ON` and run under
AddressSanitizer. With an LLVM clang that ships libFuzzer, as on Linux,
they are coverage-guided libFuzzer binaries; CI runs each for 60 seconds
on every push. Apple clang has no libFuzzer, so on macOS the same targets
link a replay driver that runs the seed corpus and random mutations of it:

```bash
cmake -S native -B native/build/fuzz -G Ninja -DJACKDAW_BUILD_FUZZERS=ON -DJACKDAW_SANITIZE=address
```

```bash
native/build/fuzz/fuzz/jackdaw_index_load_fuzz native/fuzz/corpus/index 20000
```

Seed inputs live in `native/fuzz/corpus`.

## Findings

### llama.cpp hangs on a reversed repetition (fixed in jackdaw)

The grammar fuzzer found that llama.cpp 0.6.0's GBNF parser never returns
on a repetition whose minimum is larger than its maximum. The 22 byte
grammar

```text
root ::= "a"{2,1}
```

grew to 934 MB in ten seconds and kept growing. The parser computes the
number of optional copies as `max_times - min_times` in unsigned 64-bit
arithmetic, so 1 - 2 wraps to about 1.8e19, and its size guard
(`MAX_REPETITION_THRESHOLD`) only looks at `max_times`.

Grammars that jackdaw compiles from schemas, including schemas from MCP
servers, never contain such a range. Raw grammar text does reach the
parser through `NativeGenerateOptions.grammar` and the C function
`jackdaw_session_generate`, so `libjackdaw` now checks every grammar first
(`native/src/grammar_guard.cpp`) and refuses reversed ranges with
`JACKDAW_ERR_GRAMMAR`. The check skips string literals, character classes
and comments. The grammar fuzz target goes through the same check, so it
tests what reaches llama.cpp through jackdaw. `toolCallGrammar` also
refuses a `maxCalls` outside 1 to 64.

The upstream bug is still present in llama.cpp; it should be reported to
the llama.cpp project.

### llama.cpp runs out of memory on many repetitions (open)

On 2026-10-15 a 60 second CI run of the grammar fuzzer stopped with
libFuzzer's out-of-memory report: 2,189 MB used against a 2,048 MB limit,
most of it in the parser's table of rule names. The log did not include
the input, and neither the same seed nor a 25 minute run found it again.

llama.cpp writes out one helper rule for every optional repetition and
limits each repetition to 2,000, but the limit applies to each item on
its own, so a 4 KB grammar of many bounded repetitions builds a very
large number of rules: 400 repetitions of `{0,1999}` take 225 MB under
AddressSanitizer. Two changes keep jackdaw's own grammars far from this:

- The Dart compiler writes repetition bounds only up to 64 and leaves
  larger `minItems` and `maxItems` to validation, so a schema from an MCP
  server cannot ask for thousands of rules.
- CI now keeps every input a fuzzer fails on as the `fuzz-findings`
  artifact, and the `fuzz` workflow runs the grammar fuzzer for as long
  as asked.

Raw grammar text from an app is still parsed as given. If the input
turns up, `grammar_guard` will get a limit on the total repetition count.

## Results

- Grammar parser behind the guard: 2,000 mutations of the seed grammars
  under AddressSanitizer and UndefinedBehaviorSanitizer on macOS, no
  reports; 1,887 of them were correctly rejected as malformed.
- Index loader: 20,000 mutated files under AddressSanitizer, no reports.
- Schema compiler: 1,000 grammars (500 schemas, 500 tool call grammars)
  all parse in llama.cpp. The random schemas now include optional
  properties, unions, anyOf, maps and array bounds, and the corpus adds
  the grammars of the A2UI messages and replies for the basic catalog.
- Grammar parser, 25 minutes of libFuzzer in CI with a 2 GB limit: no
  reports.
