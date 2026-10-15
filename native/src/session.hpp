#pragma once

#include <atomic>
#include <condition_variable>
#include <cstdint>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <utility>
#include <vector>

#include "jackdaw.h"
#include "llama.h"
#include "piece_ring.hpp"
#include "threads.hpp"

struct jackdaw_model;

namespace jackdaw {

/// One queued generation, owning copies of every caller buffer.
struct Job {
  int64_t id = 0;
  std::string prompt;
  /// Messages to render with the model's chat template on the worker, in
  /// place of prompt when not empty.
  std::vector<std::pair<std::string, std::string>> chat;
  jackdaw_generate_params params{};
  std::optional<std::string> grammar;
};

}

/// A context, its worker thread and the state reused across turns.
struct jackdaw_session {
  jackdaw_session(jackdaw_model& owner, llama_context* ctx,
                  jackdaw_event_callback on_event, int32_t batch, int32_t threads);
  ~jackdaw_session();
  jackdaw_session(const jackdaw_session&) = delete;
  jackdaw_session& operator=(const jackdaw_session&) = delete;

  /// Queues job; returns JACKDAW_ERR_BUSY while another job runs.
  int32_t submit(jackdaw::Job job);

  /// Requests cancellation of id if it is the running job.
  void cancel(int64_t id);

  /// Emits the final event of id after marking the session idle.
  void finish(int64_t id, int32_t kind, int32_t value);

  jackdaw_model& model;
  jackdaw::Pool pool;
  llama_context* context;
  jackdaw_event_callback callback;
  int32_t batch_tokens;
  jackdaw::PieceRing ring{64};
  std::vector<llama_token> cached;
  std::atomic<bool> cancelled{false};
  std::atomic<int64_t> active{-1};
  mutable std::mutex state_mutex;
  jackdaw_session_stats stats{};
  std::string error;

 private:
  void run();

  std::mutex mutex_;
  std::condition_variable wake_;
  std::optional<jackdaw::Job> pending_;
  bool stopping_ = false;
  std::thread worker_;
};
