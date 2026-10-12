#pragma once

#include <string>
#include <string_view>
#include <vector>

#include "llama.h"

namespace jackdaw {

/// Tokenizes text, adding the BOS token only when text does not already
/// start with it, so chat templates that render BOS are not doubled.
std::vector<llama_token> tokenize(const llama_vocab* vocab, std::string_view text);

/// Returns the text of token without special-token markup.
std::string piece(const llama_vocab* vocab, llama_token token);

}
