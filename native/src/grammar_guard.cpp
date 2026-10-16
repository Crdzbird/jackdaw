#include "grammar_guard.hpp"

#include <cctype>
#include <cstddef>
#include <cstdint>

namespace jackdaw {

namespace {

bool digit(char c) { return std::isdigit(static_cast<unsigned char>(c)) != 0; }

std::size_t skip_spaces(std::string_view text, std::size_t at) {
  while (at < text.size()) {
    const char c = text[at];
    if (c == '#') {
      while (at < text.size() && text[at] != '\n' && text[at] != '\r') ++at;
      continue;
    }
    if (c != ' ' && c != '\t' && c != '\n' && c != '\r') break;
    ++at;
  }
  return at;
}

std::size_t read_count(std::string_view text, std::size_t at, uint64_t& value) {
  value = 0;
  while (at < text.size() && digit(text[at])) {
    value = value > UINT64_MAX / 10 ? UINT64_MAX : value * 10 + static_cast<uint64_t>(text[at] - '0');
    ++at;
  }
  return at;
}

/// The bytes llama.cpp's grammar parser takes for one character starting
/// with lead: it trusts the lead byte of a UTF-8 sequence and reads its
/// continuation bytes unchecked, whatever they are, a quote included.
std::size_t utf8_length(unsigned char lead) {
  static constexpr std::size_t lengths[] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 3, 4};
  return lengths[lead >> 4];
}

std::size_t skip_quoted(std::string_view text, std::size_t at, char close) {
  ++at;
  while (at < text.size() && text[at] != close) {
    at += text[at] == '\\' ? 2 : utf8_length(static_cast<unsigned char>(text[at]));
  }
  return at;
}

}

std::optional<std::string> grammar_problem(std::string_view text) {
  const auto grammar = text.substr(0, text.find('\0'));
  for (std::size_t at = 0; at < grammar.size(); ++at) {
    const char c = grammar[at];
    if (c == '"') at = skip_quoted(grammar, at, '"');
    if (c == '[') at = skip_quoted(grammar, at, ']');
    if (c == '#') {
      while (at < grammar.size() && grammar[at] != '\n') ++at;
    }
    if (c != '{') continue;
    uint64_t low = 0;
    uint64_t high = 0;
    std::size_t next = skip_spaces(grammar, at + 1);
    if (next >= grammar.size() || !digit(grammar[next])) continue;
    next = skip_spaces(grammar, read_count(grammar, next, low));
    if (next >= grammar.size() || grammar[next] != ',') continue;
    next = skip_spaces(grammar, next + 1);
    if (next >= grammar.size() || !digit(grammar[next])) continue;
    read_count(grammar, next, high);
    if (low > high) {
      return "repetition {" + std::to_string(low) + "," + std::to_string(high) +
             "} has a minimum above its maximum";
    }
  }
  return std::nullopt;
}

}
