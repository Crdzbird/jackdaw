#pragma once

#include <algorithm>
#include <cstdint>
#include <thread>

#include "ggml-cpu.h"
#include "llama.h"

namespace jackdaw {

/// Worker threads used when the caller picks none: the core count, at most
/// four, which keeps big cores busy without waking every little core.
inline int32_t default_threads() {
  const auto hardware = static_cast<int32_t>(std::thread::hardware_concurrency());
  return std::clamp(hardware, 1, 4);
}

/// A ggml thread pool kept for the whole life of a context. Without one,
/// ggml starts and joins a pool of its own for every graph it computes,
/// which is once per generated token.
class Pool {
 public:
  explicit Pool(int32_t threads) {
    auto params = ggml_threadpool_params_default(threads);
    pool_ = ggml_threadpool_new(&params);
  }
  ~Pool() {
    if (pool_ != nullptr) ggml_threadpool_free(pool_);
  }
  Pool(const Pool&) = delete;
  Pool& operator=(const Pool&) = delete;

  /// Makes context compute on this pool, for single tokens and batches.
  void attach(llama_context* context) const {
    if (pool_ != nullptr) llama_attach_threadpool(context, pool_, pool_);
  }

 private:
  ggml_threadpool* pool_ = nullptr;
};

}
