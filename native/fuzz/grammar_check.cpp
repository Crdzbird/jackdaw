#include <filesystem>
#include <fstream>
#include <iostream>
#include <iterator>
#include <string>

#include "llama-grammar.h"

/// Parses every grammar file in a folder with llama.cpp's parser and fails
/// when one does not parse. The folder holds grammars that jackdaw's schema
/// compiler wrote for random schemas, so every one must be valid.
/// Usage: grammar_check <dir>
int main(int argc, char** argv) {
  if (argc != 2) {
    std::cerr << "usage: grammar_check <dir>\n";
    return 2;
  }
  int checked = 0;
  int invalid = 0;
  for (const auto& entry : std::filesystem::directory_iterator(argv[1])) {
    std::ifstream file(entry.path(), std::ios::binary);
    const std::string text{std::istreambuf_iterator<char>(file), std::istreambuf_iterator<char>()};
    llama_grammar_parser parser;
    ++checked;
    if (!parser.parse(text.c_str()) || parser.rules.empty()) {
      ++invalid;
      std::cerr << "invalid: " << entry.path() << "\n";
    }
  }
  std::cout << checked << " grammars, " << invalid << " invalid\n";
  return invalid == 0 && checked > 0 ? 0 : 1;
}
