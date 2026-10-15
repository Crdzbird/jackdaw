#include <vector>

#include "error.hpp"
#include "jackdaw.h"
#include "llama.h"
#include "session.hpp"

namespace {

/// Marks the session busy for a state transfer, as a generation would.
constexpr int64_t kStateTransfer = -2;

/// Claims session for a state transfer; returns false while it generates.
bool claim(jackdaw_session& session) {
  int64_t idle = -1;
  return session.active.compare_exchange_strong(idle, kStateTransfer);
}

}

extern "C" {

int32_t jackdaw_session_save(jackdaw_session* session, const char* path) {
  return jackdaw::guarded([&] {
    if (session == nullptr || path == nullptr) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "session and path are required");
    }
    if (!claim(*session)) return jackdaw::fail(JACKDAW_ERR_BUSY, "the session is generating");
    const auto& tokens = session->cached;
    const auto written = llama_state_seq_save_file(session->context, path, 0, tokens.data(),
                                                   tokens.size());
    session->active = -1;
    if (written == 0) return jackdaw::fail(JACKDAW_ERR_IO, "cannot write the session state");
    return static_cast<int32_t>(JACKDAW_OK);
  });
}

int32_t jackdaw_session_load(jackdaw_session* session, const char* path, int32_t* out_tokens) {
  return jackdaw::guarded([&] {
    if (session == nullptr || path == nullptr || out_tokens == nullptr) {
      return jackdaw::fail(JACKDAW_ERR_INVALID_ARGUMENT, "session, path and out are required");
    }
    if (!claim(*session)) return jackdaw::fail(JACKDAW_ERR_BUSY, "the session is generating");
    auto* memory = llama_get_memory(session->context);
    llama_memory_clear(memory, true);
    std::vector<llama_token> tokens(llama_n_ctx(session->context));
    std::size_t count = 0;
    const auto read = llama_state_seq_load_file(session->context, path, 0, tokens.data(),
                                                tokens.size(), &count);
    if (read == 0) {
      llama_memory_clear(memory, true);
      session->cached.clear();
      session->active = -1;
      return jackdaw::fail(JACKDAW_ERR_IO, "cannot read a session state for this model");
    }
    tokens.resize(count);
    session->cached = std::move(tokens);
    *out_tokens = static_cast<int32_t>(count);
    session->active = -1;
    return static_cast<int32_t>(JACKDAW_OK);
  });
}

}
