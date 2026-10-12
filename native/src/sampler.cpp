#include "sampler.hpp"

namespace jackdaw {

Sampler make_sampler(const llama_vocab* vocab, const Job& job) {
  Sampler chain(llama_sampler_chain_init(llama_sampler_chain_default_params()));
  const auto& p = job.params;
  if (job.grammar.has_value()) {
    auto* grammar = llama_sampler_init_grammar(vocab, job.grammar->c_str(), "root");
    if (grammar == nullptr) return nullptr;
    llama_sampler_chain_add(chain.get(), grammar);
  }
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

}
