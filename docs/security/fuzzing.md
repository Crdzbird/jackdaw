# Fuzzing

Phase 6 fuzzes the inputs that reach native code from outside the app.

## Targets

| Target | Input | Why it matters |
|---|---|---|
| `jackdaw_grammar_fuzz` | Arbitrary text into llama.cpp's GBNF parser | Grammars are compiled from schemas, and schemas can come from MCP servers |
| `jackdaw_index_load_fuzz` | Arbitrary bytes as a vector index file | Apps open index files they may not have written |
| `jackdaw_grammar_check` | Every grammar the Dart compiler writes for 500 random schemas | The compiler must never emit a grammar llama.cpp rejects |

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

## Results

- Grammar parser behind the guard: 2,000 mutations of the seed grammars
  under AddressSanitizer and UndefinedBehaviorSanitizer on macOS, no
  reports; 1,887 of them were correctly rejected as malformed.
- Index loader: 20,000 mutated files under AddressSanitizer, no reports.
- Schema compiler: 1,000 grammars (500 schemas, 500 tool call grammars)
  all parse in llama.cpp.
