#include "text.hpp"

#include <stdexcept>

namespace jackdaw {

namespace {

std::string special_piece(const llama_vocab* vocab, llama_token token) {
  char buffer[64];
  const auto n = llama_token_to_piece(vocab, token, buffer, sizeof buffer, 0, true);
  return n > 0 ? std::string(buffer, static_cast<std::size_t>(n)) : std::string();
}

}

std::vector<llama_token> tokenize(const llama_vocab* vocab, std::string_view text) {
  const auto bos = llama_vocab_bos(vocab);
  const auto bos_text = bos == LLAMA_TOKEN_NULL ? std::string() : special_piece(vocab, bos);
  const bool add_bos = bos_text.empty() || !text.starts_with(bos_text);
  const auto length = static_cast<int32_t>(text.size());
  const auto needed = -llama_tokenize(vocab, text.data(), length, nullptr, 0, add_bos, true);
  if (needed <= 0) return {};
  std::vector<llama_token> tokens(static_cast<std::size_t>(needed));
  const auto n = llama_tokenize(vocab, text.data(), length, tokens.data(), needed, add_bos, true);
  if (n != needed) throw std::runtime_error("tokenization failed");
  return tokens;
}

std::string piece(const llama_vocab* vocab, llama_token token) {
  std::string out(32, '\0');
  auto n = llama_token_to_piece(vocab, token, out.data(), static_cast<int32_t>(out.size()), 0, false);
  if (n < 0) {
    out.resize(static_cast<std::size_t>(-n));
    n = llama_token_to_piece(vocab, token, out.data(), static_cast<int32_t>(out.size()), 0, false);
  }
  out.resize(n > 0 ? static_cast<std::size_t>(n) : 0);
  return out;
}

}
