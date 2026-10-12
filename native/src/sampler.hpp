#pragma once

#include <memory>
#include <optional>

#include "llama.h"
#include "session.hpp"

namespace jackdaw {

struct SamplerDeleter {
  void operator()(llama_sampler* sampler) const { llama_sampler_free(sampler); }
};

using Sampler = std::unique_ptr<llama_sampler, SamplerDeleter>;

/// The sampling chain for a job plus its optional grammar.
struct Samplers {
  Sampler chain;
  Sampler grammar;
};

/// Builds the samplers for job, or returns nothing when its grammar does
/// not parse.
std::optional<Samplers> make_samplers(const llama_vocab* vocab, const Job& job);

/// Picks the next token. The grammar only checks the token the chain chose
/// and scores the whole vocabulary when that token is rejected, which keeps
/// constrained decoding close to the speed of free text.
llama_token sample(Samplers& samplers, llama_context* context, const llama_vocab* vocab);

}
