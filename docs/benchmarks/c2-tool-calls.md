# Claim C2: tool calls from local models

Date: 2026-10-13. Status: met for all three families (Qwen, Llama,
Gemma): every call is well-formed. How well each model decides when to
call a tool varies by family; see below.

Claim C2: at least 98% well-formed tool calls across three model families
(Qwen, Llama, Gemma) with no per-family parser.

## How tool calling works

The same code serves `LocalModel` (native) and `WebLocalModel` (web):

- Tools are described in the system prompt in the Hermes format, and
  earlier calls and results are written back into the history as
  `<tool_call>` and `<tool_response>` blocks.
- A GBNF grammar built from the tool schemas lets the model either answer
  in free text (or JSON for a response schema) or write one tool call
  whose arguments match that tool's schema. One call per turn is the
  default because small models repeated a call until the token limit.
- A decoder turns the call block into a `ToolCallEvent`, and fails on a
  call cut off by the token limit rather than passing it to a tool.

Nothing in this path depends on the model family.

## Benchmark

24 prompts against four tools (`get_weather`, `set_timer`, `send_email`,
`find_contact`): 16 that need a tool and 8 general questions that need
none. Temperature 0. A call is well-formed when it parses and its
arguments pass the tool's schema; the choice is right when the model
calls the expected tool or, for general questions, none; the arguments
are right when the key fields match. Runner:
`apps/jackdaw_bench/lib/src/tool_bench.dart`, through
`tool/run_android.sh <device> <model> tools` or `dart run
tool/tool_bench.dart <model.gguf>` on the desktop.

## Results

| Model | Device | Calls | Well-formed | Right choice | Right arguments |
|---|---|---|---|---|---|
| Qwen2.5-1.5B-Instruct Q4_K_M | Pixel 7 Pro (CPU) | 15 | 100% | 23/24 (96%) | 23/24 (96%) |
| Qwen2.5-1.5B-Instruct Q4_K_M | MacBook (Metal) | 15 | 100% | 23/24 (96%) | 23/24 (96%) |
| Qwen2.5-3B-Instruct Q4_K_M | MacBook (Metal) | 14 | 100% | 22/24 (92%) | 22/24 (92%) |
| Llama-3.2-3B-Instruct Q4_K_M | MacBook (Metal) | 24 | 100% | 16/24 (67%) | 16/24 (67%) |
| gemma-2-2b-it Q4_K_M | MacBook (Metal) | 24 | 100% | 15/24 (63%) | 15/24 (63%) |

Every call is well-formed because the grammar makes any other output
impossible, whatever the family. When a model called the right tool, its
arguments were right every time.

The families differ in when they call:

- Qwen, trained on this format, misses at most one or two calls by
  answering directly instead.
- Llama 3.2 3B calls a tool for every general question too, for example
  `find_contact` for "What is the capital of France?". Without the
  grammar it writes the same calls, so this is the model's own tendency.
  Rule-first wording, a worked example and a yes or no decision step did
  not fix it without hurting Qwen (the decision step dropped Qwen to
  7/24).
- Gemma 2 2B wrapped its calls in an XML code fence, which the grammar
  read as a plain answer. The instructions now say to start the reply
  with `<tool_call>` itself; that took Gemma from 5/24 to 15/24 and Qwen
  from 22/24 to 23/24, and left Llama unchanged. Gemma now over-calls
  like Llama.

For Llama and Gemma at these sizes, offer tools only on screens where a
tool is likely, or keep `requiresApproval` on tools with side effects, so
a needless call is visible and cheap to reject.
