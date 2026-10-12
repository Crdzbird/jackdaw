#include "sampler.hpp"

#include <cmath>
#include <vector>

namespace jackdaw {

namespace {

Sampler make_chain(const jackdaw_generate_params& p) {
  Sampler chain(llama_sampler_chain_init(llama_sampler_chain_default_params()));
  if (p.temperature <= 0.0F) {
    llama_sampler_chain_add(chain.get(), llama_sampler_init_greedy());
    return chain;
  }
  if (p.top_k > 0) llama_sampler_chain_add(chain.get(), llama_sampler_init_top_k(p.top_k));
  if (p.top_p > 0.0F && p.top_p < 1.0F) {
    llama_sampler_chain_add(chain.get(), llama_sampler_init_top_p(p.top_p, 1));
  }
  llama_sampler_chain_add(chain.get(), llama_sampler_init_temp(p.temperature));
  llama_sampler_chain_add(chain.get(), llama_sampler_init_dist(p.seed));
  return chain;
}

bool allowed(llama_sampler* grammar, llama_token token) {
  llama_token_data single{token, 1.0F, 0.0F};
  llama_token_data_array one{&single, 1, -1, false};
  llama_sampler_apply(grammar, &one);
  return std::isfinite(single.logit);
}

llama_token resample(Samplers& samplers, llama_context* context, const llama_vocab* vocab) {
  const auto count = llama_vocab_n_tokens(vocab);
  const float* logits = llama_get_logits_ith(context, -1);
  std::vector<llama_token_data> candidates(static_cast<std::size_t>(count));
  for (llama_token id = 0; id < count; ++id) {
    candidates[static_cast<std::size_t>(id)] = {id, logits[id], 0.0F};
  }
  llama_token_data_array all{candidates.data(), candidates.size(), -1, false};
  llama_sampler_apply(samplers.grammar.get(), &all);
  llama_sampler_apply(samplers.chain.get(), &all);
  return all.data[all.selected].id;
}

}

std::optional<Samplers> make_samplers(const llama_vocab* vocab, const Job& job) {
  Samplers samplers{make_chain(job.params), nullptr};
  if (job.grammar.has_value()) {
    samplers.grammar.reset(llama_sampler_init_grammar(vocab, job.grammar->c_str(), "root"));
    if (!samplers.grammar) return std::nullopt;
  }
  return samplers;
}

llama_token sample(Samplers& samplers, llama_context* context, const llama_vocab* vocab) {
  auto token = llama_sampler_sample(samplers.chain.get(), context, -1);
  if (!samplers.grammar) return token;
  if (!allowed(samplers.grammar.get(), token)) token = resample(samplers, context, vocab);
  llama_sampler_accept(samplers.grammar.get(), token);
  return token;
}

}
