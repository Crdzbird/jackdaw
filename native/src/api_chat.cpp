#include <algorithm>
#include <utility>

#include "error.hpp"
#include "jackdaw.h"
#include "model.hpp"
#include "session.hpp"
#include "submit.hpp"

extern "C" {

int32_t jackdaw_session_generate_chat(jackdaw_session* session, int64_t request_id,
                                      const jackdaw_chat_message* messages, int32_t count,
                                      const jackdaw_generate_params* params) {
  return jackdaw::guarded([&] {
    if (session == nullptr || messages == nullptr || count <= 0 || params == nullptr ||
        request_id < 0) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "invalid generate arguments");
    }
    if (session->model.chat_template.empty()) {
      return jackdaw::fail(JACKDAW_ERR_NOT_FOUND, "model has no chat template");
    }
    jackdaw::Job job;
    job.id = request_id;
    for (int32_t i = 0; i < count; ++i) {
      if (messages[i].role == nullptr || messages[i].content == nullptr) {
        return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "message fields are required");
      }
      job.chat.emplace_back(messages[i].role, messages[i].content);
    }
    return jackdaw::submit_generation(*session, std::move(job), *params);
  });
}

int32_t jackdaw_session_set_threads(jackdaw_session* session, int32_t generate, int32_t batch) {
  return jackdaw::guarded([&] {
    if (session == nullptr || generate < 1 || batch < 1) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "session and thread counts are required");
    }
    int64_t idle = -1;
    if (!session->active.compare_exchange_strong(idle, -3)) {
      return jackdaw::fail(JACKDAW_ERR_BUSY, "the session is generating");
    }
    const auto most = session->pool.threads();
    llama_set_n_threads(session->context, std::min(generate, most), std::min(batch, most));
    session->active = -1;
    return static_cast<int32_t>(JACKDAW_OK);
  });
}

}
