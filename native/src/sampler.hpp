#pragma once

#include <memory>

#include "llama.h"
#include "session.hpp"

namespace jackdaw {

struct SamplerDeleter {
  void operator()(llama_sampler* sampler) const { llama_sampler_free(sampler); }
};

using Sampler = std::unique_ptr<llama_sampler, SamplerDeleter>;

/// Builds the sampler chain for job, or returns null when its grammar does
/// not parse.
Sampler make_sampler(const llama_vocab* vocab, const Job& job);

}
