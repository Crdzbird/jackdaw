#include <algorithm>
#include <cstring>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include "error.hpp"
#include "grammar_guard.hpp"
#include "submit.hpp"
#include "live_objects.hpp"
#include "jackdaw.h"
#include "model.hpp"
#include "session.hpp"
#include "text.hpp"
#include "threads.hpp"

namespace {

void silent_log(ggml_log_level, const char*, void*) {}

void init_backend() {
  static std::once_flag once;
  std::call_once(once, [] {
    llama_log_set(silent_log, nullptr);
    llama_backend_init();
  });
}

int32_t copy_out(const std::string& text, char* buffer, int32_t capacity, int32_t* out_len) {
  if (out_len == nullptr || capacity < 0 || (buffer == nullptr && capacity > 0)) {
    return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "invalid output buffer");
  }
  *out_len = static_cast<int32_t>(text.size());
  if (*out_len > capacity) return jackdaw::fail(JACKDAW_ERR_BUFFER_TOO_SMALL, "buffer too small");
  if (!text.empty()) std::memcpy(buffer, text.data(), text.size());
  return JACKDAW_OK;
}

}

extern "C" {

int32_t jackdaw_abi_version(void) { return JACKDAW_ABI_VERSION; }

const char* jackdaw_cpu_requirements(void) { return JACKDAW_CPU_REQUIREMENTS; }

const char* jackdaw_last_error(void) { return jackdaw::last_error(); }

int32_t jackdaw_model_load(const char* path, const jackdaw_model_params* params,
                           jackdaw_model** out) {
  return jackdaw::guarded([&] {
    if (path == nullptr || out == nullptr) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "path and out are required");
    }
    init_backend();
    auto settings = llama_model_default_params();
    settings.n_gpu_layers = params != nullptr ? params->gpu_layers : 0;
    settings.load_mode = params != nullptr && params->use_mmap != 0 ? LLAMA_LOAD_MODE_MMAP
                                                                    : LLAMA_LOAD_MODE_NONE;
    auto* loaded = llama_model_load_from_file(path, settings);
    if (loaded == nullptr) return jackdaw::fail(JACKDAW_ERR_IO, std::string("cannot load ") + path);
    *out = new jackdaw_model(loaded);
    jackdaw::track(*out);
    return static_cast<int32_t>(JACKDAW_OK);
  });
}

void jackdaw_model_free(jackdaw_model* model) {
  if (jackdaw::untrack(model)) delete model;
}

int32_t jackdaw_model_get_info(const jackdaw_model* model, jackdaw_model_info* out) {
  if (model == nullptr || out == nullptr) {
    return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "model and out are required");
  }
  out->parameters = llama_model_n_params(model->model);
  out->size_bytes = llama_model_size(model->model);
  out->context_train = llama_model_n_ctx_train(model->model);
  return JACKDAW_OK;
}

int32_t jackdaw_model_tokenize(const jackdaw_model* model, const char* text, int32_t text_len,
                               int32_t add_special, int32_t* tokens, int32_t capacity,
                               int32_t* out_count) {
  return jackdaw::guarded([&] {
    if (model == nullptr || text == nullptr || text_len < 0 || out_count == nullptr ||
        capacity < 0 || (tokens == nullptr && capacity > 0)) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "invalid tokenize arguments");
    }
    const auto n = llama_tokenize(model->vocab, text, text_len, tokens, capacity,
                                  add_special != 0, true);
    if (n == INT32_MIN) return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "text too long");
    *out_count = n < 0 ? -n : n;
    if (n < 0) return jackdaw::fail(JACKDAW_ERR_BUFFER_TOO_SMALL, "token buffer too small");
    return static_cast<int32_t>(JACKDAW_OK);
  });
}

int32_t jackdaw_model_apply_template(const jackdaw_model* model,
                                     const jackdaw_chat_message* messages, int32_t count,
                                     int32_t add_assistant, char* buffer, int32_t capacity,
                                     int32_t* out_len) {
  return jackdaw::guarded([&] {
    if (model == nullptr || count < 0 || (messages == nullptr && count > 0)) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "invalid messages");
    }
    if (model->chat_template.empty()) {
      return jackdaw::fail(JACKDAW_ERR_NOT_FOUND, "model has no chat template");
    }
    jackdaw::Chat chat;
    for (int32_t i = 0; i < count; ++i) {
      if (messages[i].role == nullptr || messages[i].content == nullptr) {
        return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "message fields are required");
      }
      chat.emplace_back(messages[i].role, messages[i].content);
    }
    const auto rendered = jackdaw::render_chat(*model, chat, add_assistant != 0);
    if (!rendered) return jackdaw::fail(JACKDAW_ERR_NOT_FOUND, "chat template is not supported");
    return copy_out(*rendered, buffer, capacity, out_len);
  });
}

int32_t jackdaw_session_create(jackdaw_model* model, const jackdaw_session_params* params,
                               jackdaw_event_callback callback, jackdaw_session** out) {
  return jackdaw::guarded([&] {
    if (model == nullptr || callback == nullptr || out == nullptr) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "model, callback and out are required");
    }
    const auto context_tokens = params != nullptr && params->context_tokens > 0 ? params->context_tokens : 4096;
    const auto threads = params != nullptr && params->threads > 0 ? params->threads : jackdaw::default_threads();
    const auto batch = params != nullptr && params->batch_tokens > 0 ? params->batch_tokens : 512;
    auto settings = llama_context_default_params();
    settings.n_ctx = static_cast<uint32_t>(context_tokens);
    settings.n_batch = static_cast<uint32_t>(batch);
    settings.n_ubatch = static_cast<uint32_t>(batch);
    settings.n_threads = threads;
    settings.n_threads_batch = threads;
    settings.no_perf = true;
    auto* context = llama_init_from_model(model->model, settings);
    if (context == nullptr) return jackdaw::fail(JACKDAW_ERR_MODEL, "cannot create context");
    *out = new jackdaw_session(*model, context, callback, batch, threads);
    jackdaw::track(*out);
    return static_cast<int32_t>(JACKDAW_OK);
  });
}

void jackdaw_session_free(jackdaw_session* session) {
  if (jackdaw::untrack(session)) delete session;
}

int32_t jackdaw_session_generate(jackdaw_session* session, int64_t request_id, const char* prompt,
                                 int32_t prompt_len, const jackdaw_generate_params* params) {
  return jackdaw::guarded([&] {
    if (session == nullptr || prompt == nullptr || prompt_len <= 0 || params == nullptr ||
        request_id < 0) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "invalid generate arguments");
    }
    jackdaw::Job job;
    job.id = request_id;
    job.prompt.assign(prompt, static_cast<std::size_t>(prompt_len));
    return jackdaw::submit_generation(*session, std::move(job), *params);
  });
}

int32_t jackdaw_session_cancel(jackdaw_session* session, int64_t request_id) {
  if (session == nullptr) return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "session is required");
  session->cancel(request_id);
  return JACKDAW_OK;
}

int32_t jackdaw_session_read(jackdaw_session* session, int32_t slot, char* buffer,
                             int32_t capacity, int32_t* out_len) {
  if (session == nullptr) return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "session is required");
  const auto status = session->ring.read(slot, buffer, capacity, out_len);
  if (status != JACKDAW_OK) return jackdaw::fail(status, "cannot read slot");
  return JACKDAW_OK;
}

int32_t jackdaw_session_get_stats(const jackdaw_session* session, jackdaw_session_stats* out) {
  if (session == nullptr || out == nullptr) {
    return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "session and out are required");
  }
  std::lock_guard lock(session->state_mutex);
  *out = session->stats;
  return JACKDAW_OK;
}

int32_t jackdaw_session_error(const jackdaw_session* session, char* buffer, int32_t capacity,
                              int32_t* out_len) {
  return jackdaw::guarded([&] {
    if (session == nullptr) return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "session is required");
    std::string message;
    {
      std::lock_guard lock(session->state_mutex);
      message = session->error;
    }
    return copy_out(message, buffer, capacity, out_len);
  });
}

}
