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

The upstream bug is still present in llama.cpp master (checked at
620d2225cc on 2026-10-15); an earlier report, #23108, was closed as
stale without a fix.

### The guard missed ranges split by newlines or comments (fixed)

On 2026-10-15 a 60 second CI run of the grammar fuzzer stopped with
libFuzzer's out-of-memory report: 2,189 MB used, most of it in the
parser's table of rule names. The log did not include the input, and the
same seed did not find it again, but the stack matched llama.cpp issue
#23108, a report of the reversed-range bug above that was closed as
stale without a fix.

Inside parentheses llama.cpp skips newlines and `#` comments within
`{m,n}`, and the guard only skipped spaces and tabs, so it let these
through:

```text
root ::= ("a"{5,
0})
root ::= ("a"{5 # note
,0})
```

Both made the parser grow to 2 GB in ten seconds. The guard now skips
newlines, carriage returns and comments the way the parser does, and
refuses both; they are in `native/tests/grammar_guard_test.cpp`. The fix
ships in the dev.5 prebuilt libraries.

Separately, llama.cpp writes out one helper rule for every optional
repetition and limits each repetition to 2,000 on its own, so a 4 KB
grammar of many bounded repetitions builds a very large number of rules:
400 repetitions of `{0,1999}` take 225 MB under AddressSanitizer. The
Dart compiler therefore writes repetition bounds only up to 64 and leaves
larger `minItems` and `maxItems` to validation. CI keeps every input a
fuzzer fails on as the `fuzz-findings` artifact, and the `fuzz` workflow
runs the grammar fuzzer for as long as asked.

### The guard read literals differently from the parser (fixed)

On 2026-10-15 the CI grammar fuzzer ran out of memory again on a 188
byte input ending in ` i{5,3}*`, a reversed range the guard refuses.
The guard skipped quoted literals byte by byte. Inside a literal or a
character class, llama.cpp reads one character at a time with a UTF-8
decoder that trusts the lead byte: a byte `0xC0` to `0xDF` takes the next
byte with it, `0xE0` to `0xEF` the next two and `0xF0` and up the next
three, whatever they are. In the input, a lone lead byte took the
closing quote with it, so the parser read the range as grammar while the
guard still counted it as text.

The guard now steps through literals and classes the same way, and,
like the parser, stops at the first NUL byte. The input is in
`native/fuzz/regressions/grammar/utf8_swallowed_quote.bin`, which
the fuzzer replays through the guard, unlike the corpus that
`jackdaw_grammar_check` parses directly, and minimal
cases are in `native/tests/grammar_guard_test.cpp`; replaying it with
10,000 mutations gives no report. The fix ships in the dev.6 prebuilt
libraries.

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
