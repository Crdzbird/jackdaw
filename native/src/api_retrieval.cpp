#include <cmath>
#include <memory>
#include <mutex>
#include <vector>

#include "embedder.hpp"
#include "error.hpp"
#include "live_objects.hpp"
#include "jackdaw.h"
#include "model.hpp"
#include "threads.hpp"
#include "vector_index.hpp"

namespace {

bool finite(const float* values, std::size_t count) {
  for (std::size_t i = 0; i < count; ++i) {
    if (!std::isfinite(values[i])) return false;
  }
  return true;
}

}

extern "C" {

int32_t jackdaw_embedder_create(jackdaw_model* model, const jackdaw_embedder_params* params,
                                jackdaw_embedder** out) {
  return jackdaw::guarded([&] {
    if (model == nullptr || out == nullptr) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "model and out are required");
    }
    const auto tokens = params != nullptr && params->max_tokens > 0 ? params->max_tokens : 512;
    const auto threads = params != nullptr && params->threads > 0 ? params->threads
                                                                  : jackdaw::default_threads();
    auto settings = llama_context_default_params();
    settings.n_ctx = static_cast<uint32_t>(tokens);
    settings.n_batch = static_cast<uint32_t>(tokens);
    settings.n_ubatch = static_cast<uint32_t>(tokens);
    settings.n_seq_max = 1;
    settings.n_threads = threads;
    settings.n_threads_batch = threads;
    settings.embeddings = true;
    settings.no_perf = true;
    auto* context = llama_init_from_model(model->model, settings);
    if (context == nullptr) return jackdaw::fail(JACKDAW_ERR_MODEL, "cannot create context");
    *out = new jackdaw_embedder(*model, context, tokens);
    jackdaw::track(*out);
    return static_cast<int32_t>(JACKDAW_OK);
  });
}

void jackdaw_embedder_free(jackdaw_embedder* embedder) {
  if (jackdaw::untrack(embedder)) delete embedder;
}

int32_t jackdaw_embedder_dimensions(const jackdaw_embedder* embedder) {
  return embedder == nullptr ? 0 : embedder->dimensions;
}

int32_t jackdaw_embedder_embed(jackdaw_embedder* embedder, const char* const* texts,
                               const int32_t* lengths, int32_t count, float* out,
                               int64_t capacity) {
  return jackdaw::guarded([&] {
    if (embedder == nullptr || count < 0 || (count > 0 && (texts == nullptr ||
        lengths == nullptr || out == nullptr)) ||
        capacity < static_cast<int64_t>(count) * embedder->dimensions) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "invalid embed arguments");
    }
    for (int32_t i = 0; i < count; ++i) {
      if (texts[i] == nullptr || lengths[i] < 0) {
        return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "invalid text");
      }
      const auto status = embedder->embed(texts[i], lengths[i],
                                          out + static_cast<std::ptrdiff_t>(i) * embedder->dimensions);
      if (status != JACKDAW_OK) return status;
    }
    return static_cast<int32_t>(JACKDAW_OK);
  });
}

int32_t jackdaw_index_create(int32_t dimensions, jackdaw_index** out) {
  return jackdaw::guarded([&] {
    if (dimensions <= 0 || dimensions > 65536 || out == nullptr) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "invalid index arguments");
    }
    *out = new jackdaw_index(dimensions);
    return static_cast<int32_t>(JACKDAW_OK);
  });
}

void jackdaw_index_free(jackdaw_index* index) { delete index; }

int64_t jackdaw_index_size(const jackdaw_index* index) {
  if (index == nullptr) return 0;
  std::shared_lock lock(index->mutex);
  return static_cast<int64_t>(index->keys.size());
}

int32_t jackdaw_index_dimensions(const jackdaw_index* index) {
  return index == nullptr ? 0 : index->dimensions;
}

int32_t jackdaw_index_add(jackdaw_index* index, const uint64_t* keys, const float* vectors,
                          int32_t count) {
  return jackdaw::guarded([&] {
    if (index == nullptr || count < 0 || (count > 0 && (keys == nullptr || vectors == nullptr))) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "invalid add arguments");
    }
    const auto width = static_cast<std::size_t>(index->dimensions);
    if (!finite(vectors, static_cast<std::size_t>(count) * width)) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "vectors must be finite");
    }
    for (int32_t i = 0; i < count; ++i) {
      index->add(keys[i], vectors + static_cast<std::size_t>(i) * width);
    }
    return static_cast<int32_t>(JACKDAW_OK);
  });
}

int32_t jackdaw_index_remove(jackdaw_index* index, uint64_t key, int32_t* removed) {
  return jackdaw::guarded([&] {
    if (index == nullptr || removed == nullptr) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "index and removed are required");
    }
    *removed = index->remove(key) ? 1 : 0;
    return static_cast<int32_t>(JACKDAW_OK);
  });
}

int32_t jackdaw_index_search(const jackdaw_index* index, const float* query, int32_t k,
                             uint64_t* keys, float* scores, int32_t* out_count) {
  return jackdaw::guarded([&] {
    if (index == nullptr || query == nullptr || k < 0 || out_count == nullptr ||
        (k > 0 && (keys == nullptr || scores == nullptr))) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "invalid search arguments");
    }
    if (!finite(query, static_cast<std::size_t>(index->dimensions))) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "query must be finite");
    }
    *out_count = static_cast<int32_t>(index->search(query, k, keys, scores));
    return static_cast<int32_t>(JACKDAW_OK);
  });
}

int32_t jackdaw_index_save(const jackdaw_index* index, const char* path) {
  return jackdaw::guarded([&] {
    if (index == nullptr || path == nullptr) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "index and path are required");
    }
    return jackdaw::save_index(*index, path);
  });
}

int32_t jackdaw_index_load(const char* path, jackdaw_index** out) {
  return jackdaw::guarded([&] {
    if (path == nullptr || out == nullptr) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "path and out are required");
    }
    std::unique_ptr<jackdaw_index> loaded;
    const auto status = jackdaw::load_index(path, loaded);
    if (status == JACKDAW_OK) *out = loaded.release();
    return status;
  });
}

}
