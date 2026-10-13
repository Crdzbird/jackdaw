# Claim C2: tool calls from local models

Date: 2026-10-13. Status: met for the Qwen family; Llama and Gemma not
measured yet.

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
| Qwen2.5-1.5B-Instruct Q4_K_M | MacBook (Metal) | 14 | 100% | 22/24 (92%) | 22/24 (92%) |
| Qwen2.5-3B-Instruct Q4_K_M | MacBook (Metal) | 14 | 100% | 22/24 (92%) | 22/24 (92%) |

Every call is well-formed because the grammar makes any other output
impossible. Every miss is a call the model chose not to make, for
example "What is John Smith's phone number?" answered without
`find_contact`; when the model did call the right tool, its arguments
were right every time. No general question triggered a tool.

## Open

Llama 3.2 and Gemma GGUF files are needed to cover the other two
families; they are not on this machine yet.
