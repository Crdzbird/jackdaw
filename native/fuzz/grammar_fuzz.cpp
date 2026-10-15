#include <cstddef>
#include <cstdint>
#include <string>

#include "grammar_guard.hpp"
#include "llama-grammar.h"

/// Feeds arbitrary text to llama.cpp's GBNF parser the way jackdaw does:
/// through grammar_problem first, which refuses what llama.cpp cannot
/// handle. Grammars reach the parser from schemas, and schemas can come
/// from MCP servers, so this path must never crash or hang.
extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
  const std::string text(reinterpret_cast<const char*>(data), size);
  if (jackdaw::grammar_problem(text)) return 0;
  llama_grammar_parser parser;
  parser.parse(text.c_str());
  return 0;
}
