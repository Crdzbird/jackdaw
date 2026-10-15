#include "session.hpp"

#include <utility>

#include "generator.hpp"

namespace {

bool should_abort(void* data) {
  return static_cast<jackdaw_session*>(data)->cancelled.load();
}

}

jackdaw_session::jackdaw_session(jackdaw_model& owner, llama_context* ctx,
                                 jackdaw_event_callback on_event, int32_t batch,
                                 int32_t threads)
    : model(owner),
      pool(threads),
      context(ctx),
      callback(on_event),
      batch_tokens(batch),
      worker_([this] { run(); }) {
  pool.attach(context);
  llama_set_abort_callback(context, should_abort, this);
}

jackdaw_session::~jackdaw_session() {
  {
    std::lock_guard lock(mutex_);
    stopping_ = true;
  }
  cancelled = true;
  wake_.notify_all();
  ring.wake();
  worker_.join();
  llama_free(context);
}

int32_t jackdaw_session::submit(jackdaw::Job job) {
  int64_t idle = -1;
  if (!active.compare_exchange_strong(idle, job.id)) return JACKDAW_ERR_BUSY;
  cancelled = false;
  {
    std::lock_guard lock(mutex_);
    pending_ = std::move(job);
  }
  wake_.notify_one();
  return JACKDAW_OK;
}

void jackdaw_session::cancel(int64_t id) {
  if (active.load() != id) return;
  cancelled = true;
  ring.wake();
}

void jackdaw_session::finish(int64_t id, int32_t kind, int32_t value) {
  active = -1;
  callback(id, kind, value);
}

void jackdaw_session::run() {
  for (;;) {
    jackdaw::Job job;
    {
      std::unique_lock lock(mutex_);
      wake_.wait(lock, [this] { return stopping_ || pending_.has_value(); });
      if (stopping_) return;
      job = std::move(*pending_);
      pending_.reset();
    }
    jackdaw::generate(*this, job);
  }
}
