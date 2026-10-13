#pragma once

#include <cstdint>
#include <mutex>

#include "llama.h"

struct jackdaw_model;

/// An embedding context on a model. Calls are serialized by a mutex.
struct jackdaw_embedder {
  jackdaw_embedder(jackdaw_model& owner, llama_context* ctx, int32_t tokens);
  ~jackdaw_embedder();
  jackdaw_embedder(const jackdaw_embedder&) = delete;
  jackdaw_embedder& operator=(const jackdaw_embedder&) = delete;

  /// Writes the unit-length embedding of text into out, which holds
  /// dimensions floats. Text beyond max_tokens tokens is ignored.
  int32_t embed(const char* text, int32_t length, float* out);

  jackdaw_model& model;
  llama_context* context;
  int32_t dimensions;
  int32_t max_tokens;
  std::mutex mutex;
};
