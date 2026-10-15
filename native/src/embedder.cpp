#include "embedder.hpp"

#include <algorithm>
#include <cmath>
#include <vector>

#include "error.hpp"
#include "jackdaw.h"
#include "model.hpp"

namespace {

struct Batch {
  explicit Batch(int32_t size) : value(llama_batch_init(size, 0, 1)) {}
  ~Batch() { llama_batch_free(value); }
  Batch(const Batch&) = delete;
  Batch& operator=(const Batch&) = delete;
  llama_batch value;
};

void normalize(float* values, int32_t count) {
  double sum = 0;
  for (int32_t i = 0; i < count; ++i) sum += static_cast<double>(values[i]) * values[i];
  if (sum == 0) return;
  const auto scale = static_cast<float>(1.0 / std::sqrt(sum));
  for (int32_t i = 0; i < count; ++i) values[i] *= scale;
}

}

jackdaw_embedder::jackdaw_embedder(jackdaw_model& owner, llama_context* ctx, int32_t tokens,
                                   int32_t threads)
    : model(owner),
      pool(threads),
      context(ctx),
      dimensions(llama_model_n_embd_out(owner.model)),
      max_tokens(tokens) {
  pool.attach(context);
}

jackdaw_embedder::~jackdaw_embedder() { llama_free(context); }

int32_t jackdaw_embedder::embed(const char* text, int32_t length, float* out) {
  std::lock_guard lock(mutex);
  const int32_t needed = -llama_tokenize(model.vocab, text, length, nullptr, 0, true, true);
  std::vector<llama_token> tokens(static_cast<std::size_t>(std::max(needed, 0)));
  if (needed > 0) {
    llama_tokenize(model.vocab, text, length, tokens.data(), needed, true, true);
  }
  tokens.resize(std::min(tokens.size(), static_cast<std::size_t>(max_tokens)));
  std::fill(out, out + dimensions, 0.0F);
  if (tokens.empty()) return JACKDAW_OK;
  const auto n = static_cast<int32_t>(tokens.size());
  Batch batch(n);
  for (int32_t i = 0; i < n; ++i) {
    batch.value.token[i] = tokens[static_cast<std::size_t>(i)];
    batch.value.pos[i] = i;
    batch.value.n_seq_id[i] = 1;
    batch.value.seq_id[i][0] = 0;
    batch.value.logits[i] = 1;
  }
  batch.value.n_tokens = n;
  llama_memory_clear(llama_get_memory(context), true);
  const bool encoder_only = llama_model_has_encoder(model.model) && !llama_model_has_decoder(model.model);
  const int32_t status = encoder_only ? llama_encode(context, batch.value) : llama_decode(context, batch.value);
  if (status != 0) return jackdaw::fail(JACKDAW_ERR_MODEL, "embedding failed");
  if (llama_pooling_type(context) != LLAMA_POOLING_TYPE_NONE) {
    const float* pooled = llama_get_embeddings_seq(context, 0);
    if (pooled == nullptr) return jackdaw::fail(JACKDAW_ERR_MODEL, "model returned no embedding");
    std::copy_n(pooled, dimensions, out);
    normalize(out, dimensions);
    return JACKDAW_OK;
  }
  for (int32_t i = 0; i < n; ++i) {
    const float* row = llama_get_embeddings_ith(context, i);
    if (row == nullptr) return jackdaw::fail(JACKDAW_ERR_MODEL, "model returned no embedding");
    for (int32_t d = 0; d < dimensions; ++d) out[d] += row[d];
  }
  normalize(out, dimensions);
  return JACKDAW_OK;
}
